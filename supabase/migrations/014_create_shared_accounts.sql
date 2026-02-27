-- ============================================================================
-- MIGRATION 014: Comptes Partagés / Familiaux
-- Feature critique pour l'adoption massive - Mode Couple, Famille, Roommates
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE: shared_accounts
-- Comptes partagés avec différents modes de partage
-- ----------------------------------------------------------------------------
CREATE TABLE shared_accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    
    -- Mode de partage
    sharing_mode TEXT NOT NULL CHECK(sharing_mode IN ('couple', 'family', 'roommates')),
    
    -- Configuration selon le mode
    config JSONB DEFAULT '{}'::jsonb,
    -- couple: { "income_sharing": "full|proportional|separate" }
    -- family: { "children_can_view": boolean, "children_can_add": boolean, "parent_approval": boolean }
    -- roommates: { "expense_splitting": "equal|custom", "settlement_day": integer }
    
    -- Apparence
    color TEXT DEFAULT '#E8A86C',
    icon TEXT DEFAULT 'people',
    
    -- Statut
    status TEXT DEFAULT 'active' CHECK(status IN ('active', 'archived', 'deleted')),
    
    -- Limites Pro
    max_members INTEGER DEFAULT 2,  -- Gratuit: 2, Pro: illimité
    is_pro_feature BOOLEAN DEFAULT FALSE,
    
    -- Totaux calculés (mis à jour via trigger)
    total_balance DECIMAL(12,2) DEFAULT 0,
    total_expenses_this_month DECIMAL(12,2) DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les performances
CREATE INDEX idx_shared_accounts_created_by ON shared_accounts(created_by);
CREATE INDEX idx_shared_accounts_status ON shared_accounts(status);
CREATE INDEX idx_shared_accounts_sharing_mode ON shared_accounts(sharing_mode);

-- ----------------------------------------------------------------------------
-- TABLE: shared_account_members
-- Membres d'un compte partagé avec leurs permissions
-- ----------------------------------------------------------------------------
CREATE TABLE shared_account_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    shared_account_id UUID REFERENCES shared_accounts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Rôle dans le compte partagé
    role TEXT NOT NULL CHECK(role IN ('owner', 'admin', 'member', 'child', 'viewer')),
    -- owner: créateur, tous les droits
    -- admin: gestion des membres, modification des paramètres
    -- member: ajout de transactions, lecture
    -- child: (mode famille) lecture seule ou ajout selon config
    -- viewer: lecture seule
    
    -- Permissions granulaires (override le rôle si spécifié)
    permissions JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "can_view_all_transactions": boolean,
    --   "can_add_transactions": boolean,
    --   "can_edit_transactions": boolean,
    --   "can_delete_transactions": boolean,
    --   "can_invite_members": boolean,
    --   "can_manage_settings": boolean,
    --   "can_view_analytics": boolean
    -- }
    
    -- Métadonnées du membre
    display_name TEXT,  -- Nom personnalisé dans ce groupe
    avatar_url TEXT,
    
    -- Statut d'adhésion
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    invited_by UUID REFERENCES profiles(id),
    
    -- Notification preferences pour ce groupe
    notification_prefs JSONB DEFAULT '{"new_transaction": true, "large_expense": true, "weekly_summary": true}'::jsonb,
    
    UNIQUE(shared_account_id, user_id)
);

-- Index pour les performances
CREATE INDEX idx_shared_members_account ON shared_account_members(shared_account_id);
CREATE INDEX idx_shared_members_user ON shared_account_members(user_id);
CREATE INDEX idx_shared_members_role ON shared_account_members(role);

-- ----------------------------------------------------------------------------
-- TABLE: shared_invitations
-- Invitations envoyées à rejoindre un compte partagé
-- ----------------------------------------------------------------------------
CREATE TABLE shared_invitations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    shared_account_id UUID REFERENCES shared_accounts(id) ON DELETE CASCADE NOT NULL,
    invited_by UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Informations de l'invité
    email TEXT,  -- Email de l'invité (si pas encore inscrit)
    invited_user_id UUID REFERENCES profiles(id),  -- Si déjà inscrit
    
    -- Configuration de l'invitation
    role TEXT DEFAULT 'member' CHECK(role IN ('admin', 'member', 'child', 'viewer')),
    permissions JSONB DEFAULT '{}'::jsonb,
    
    -- Token sécurisé pour l'invitation
    token TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
    
    -- Statut et expiration
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'accepted', 'declined', 'expired', 'revoked')),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
    
    -- Métadonnées
    message TEXT,  -- Message personnalisé de l'invitant
    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    
    -- Contrainte: soit email soit invited_user_id doit être présent
    CONSTRAINT chk_invitation_target CHECK (
        (email IS NOT NULL AND invited_user_id IS NULL) OR
        (email IS NULL AND invited_user_id IS NOT NULL)
    )
);

-- Index pour les performances
CREATE INDEX idx_shared_invitations_account ON shared_invitations(shared_account_id);
CREATE INDEX idx_shared_invitations_token ON shared_invitations(token);
CREATE INDEX idx_shared_invitations_email ON shared_invitations(email) WHERE email IS NOT NULL;
CREATE INDEX idx_shared_invitations_status ON shared_invitations(status);

-- ----------------------------------------------------------------------------
-- TABLE: shared_transactions
-- Transactions liées à un compte partagé
-- ----------------------------------------------------------------------------
CREATE TABLE shared_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    shared_account_id UUID REFERENCES shared_accounts(id) ON DELETE CASCADE NOT NULL,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Référence optionnelle à une transaction personnelle
    personal_transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    
    -- Détails de la transaction
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    description TEXT NOT NULL,
    category TEXT,
    subcategory TEXT,
    merchant TEXT,
    
    -- Date et statut
    transaction_date DATE NOT NULL,
    status TEXT DEFAULT 'confirmed' CHECK(status IN ('pending', 'confirmed', 'disputed', 'cancelled')),
    
    -- Répartition des dépenses (pour roommates et couples)
    split_type TEXT DEFAULT 'equal' CHECK(split_type IN ('equal', 'percentage', 'amount', 'custom')),
    split_details JSONB DEFAULT '[]'::jsonb,
    -- [
    --   { "user_id": "uuid", "amount": 50.00, "percentage": 50, "paid": true },
    --   { "user_id": "uuid", "amount": 50.00, "percentage": 50, "paid": false }
    -- ]
    
    -- Preuves et justificatifs
    receipt_url TEXT,
    
    -- Notes et commentaires
    notes TEXT,
    tags TEXT[],
    
    -- Métadonnées
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES profiles(id)
);

-- Index pour les performances
CREATE INDEX idx_shared_transactions_account ON shared_transactions(shared_account_id);
CREATE INDEX idx_shared_transactions_date ON shared_transactions(transaction_date DESC);
CREATE INDEX idx_shared_transactions_category ON shared_transactions(category);
CREATE INDEX idx_shared_transactions_created_by ON shared_transactions(created_by);
CREATE INDEX idx_shared_transactions_status ON shared_transactions(status);

-- ----------------------------------------------------------------------------
-- TABLE: shared_settlements
-- Règlements entre membres (pour roommates principalement)
-- ----------------------------------------------------------------------------
CREATE TABLE shared_settlements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    shared_account_id UUID REFERENCES shared_accounts(id) ON DELETE CASCADE NOT NULL,
    
    -- Qui paye qui
    from_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    to_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    
    -- Statut
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'completed', 'cancelled')),
    
    -- Méthode de paiement utilisée
    payment_method TEXT,
    payment_reference TEXT,
    
    -- Lié aux transactions
    related_transaction_ids UUID[],
    
    -- Dates
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    -- Validation
    CONSTRAINT chk_different_users CHECK (from_user_id != to_user_id)
);

CREATE INDEX idx_shared_settlements_account ON shared_settlements(shared_account_id);
CREATE INDEX idx_shared_settlements_from ON shared_settlements(from_user_id);
CREATE INDEX idx_shared_settlements_to ON shared_settlements(to_user_id);
CREATE INDEX idx_shared_settlements_status ON shared_settlements(status);

-- ----------------------------------------------------------------------------
-- FONCTIONS ET TRIGGERS
-- ----------------------------------------------------------------------------

-- Mise à jour automatique de updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_shared_accounts_updated_at
    BEFORE UPDATE ON shared_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shared_transactions_updated_at
    BEFORE UPDATE ON shared_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Mise à jour des totaux du compte partagé
CREATE OR REPLACE FUNCTION update_shared_account_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE shared_accounts
    SET 
        total_balance = (
            SELECT COALESCE(SUM(amount), 0)
            FROM shared_transactions
            WHERE shared_account_id = COALESCE(NEW.shared_account_id, OLD.shared_account_id)
            AND status = 'confirmed'
        ),
        total_expenses_this_month = (
            SELECT COALESCE(SUM(ABS(amount)), 0)
            FROM shared_transactions
            WHERE shared_account_id = COALESCE(NEW.shared_account_id, OLD.shared_account_id)
            AND status = 'confirmed'
            AND amount < 0
            AND transaction_date >= DATE_TRUNC('month', NOW())
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.shared_account_id, OLD.shared_account_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_shared_account_totals
    AFTER INSERT OR UPDATE OR DELETE ON shared_transactions
    FOR EACH ROW EXECUTE FUNCTION update_shared_account_totals();

-- Expiration automatique des invitations
CREATE OR REPLACE FUNCTION expire_old_invitations()
RETURNS void AS $$
BEGIN
    UPDATE shared_invitations
    SET status = 'expired'
    WHERE status = 'pending'
    AND expires_at < NOW();
END;
$$ language 'plpgsql';

-- ----------------------------------------------------------------------------
-- POLITIQUES RLS (Row Level Security)
-- ----------------------------------------------------------------------------

ALTER TABLE shared_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_account_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_settlements ENABLE ROW LEVEL SECURITY;

-- shared_accounts: visible si membre
CREATE POLICY shared_accounts_select ON shared_accounts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_accounts.id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY shared_accounts_insert ON shared_accounts
    FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY shared_accounts_update ON shared_accounts
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_accounts.id
            AND user_id = auth.uid()
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY shared_accounts_delete ON shared_accounts
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_accounts.id
            AND user_id = auth.uid()
            AND role = 'owner'
        )
    );

-- shared_account_members: visible si membre du compte
CREATE POLICY shared_members_select ON shared_account_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM shared_account_members sam
            WHERE sam.shared_account_id = shared_account_members.shared_account_id
            AND sam.user_id = auth.uid()
        )
    );

CREATE POLICY shared_members_insert ON shared_account_members
    FOR INSERT WITH CHECK (
        -- L'invité accepte son invitation
        user_id = auth.uid()
        OR
        -- Un admin invite quelqu'un
        EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_account_members.shared_account_id
            AND user_id = auth.uid()
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY shared_members_update ON shared_account_members
    FOR UPDATE USING (
        -- Soi-même
        user_id = auth.uid()
        OR
        -- Admin modifie un membre (sauf owner)
        EXISTS (
            SELECT 1 FROM shared_account_members admin
            WHERE admin.shared_account_id = shared_account_members.shared_account_id
            AND admin.user_id = auth.uid()
            AND admin.role IN ('owner', 'admin')
            AND shared_account_members.role != 'owner'
        )
    );

CREATE POLICY shared_members_delete ON shared_account_members
    FOR DELETE USING (
        -- Soi-même quitte le groupe
        user_id = auth.uid()
        OR
        -- Admin supprime un membre (sauf owner)
        EXISTS (
            SELECT 1 FROM shared_account_members admin
            WHERE admin.shared_account_id = shared_account_members.shared_account_id
            AND admin.user_id = auth.uid()
            AND admin.role IN ('owner', 'admin')
            AND shared_account_members.role != 'owner'
        )
    );

-- shared_invitations: visible si concerné
CREATE POLICY shared_invitations_select ON shared_invitations
    FOR SELECT USING (
        invited_by = auth.uid()
        OR invited_user_id = auth.uid()
        OR email = auth.email()
        OR EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_invitations.shared_account_id
            AND user_id = auth.uid()
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY shared_invitations_insert ON shared_invitations
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_invitations.shared_account_id
            AND user_id = auth.uid()
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY shared_invitations_update ON shared_invitations
    FOR UPDATE USING (
        invited_user_id = auth.uid()
        OR email = auth.email()
        OR invited_by = auth.uid()
    );

-- shared_transactions: visible si membre avec permission
CREATE POLICY shared_transactions_select ON shared_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_transactions.shared_account_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY shared_transactions_insert ON shared_transactions
    FOR INSERT WITH CHECK (
        created_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_transactions.shared_account_id
            AND user_id = auth.uid()
            AND (
                role IN ('owner', 'admin', 'member')
                OR (role = 'child' AND (permissions->>'can_add_transactions')::boolean = true)
            )
        )
    );

CREATE POLICY shared_transactions_update ON shared_transactions
    FOR UPDATE USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_transactions.shared_account_id
            AND user_id = auth.uid()
            AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY shared_transactions_delete ON shared_transactions
    FOR DELETE USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_transactions.shared_account_id
            AND user_id = auth.uid()
            AND role IN ('owner', 'admin')
        )
    );

-- shared_settlements: visible si concerné
CREATE POLICY shared_settlements_select ON shared_settlements
    FOR SELECT USING (
        from_user_id = auth.uid()
        OR to_user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_settlements.shared_account_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY shared_settlements_insert ON shared_settlements
    FOR INSERT WITH CHECK (
        from_user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM shared_account_members
            WHERE shared_account_id = shared_settlements.shared_account_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY shared_settlements_update ON shared_settlements
    FOR UPDATE USING (
        from_user_id = auth.uid()
        OR to_user_id = auth.uid()
    );

-- ----------------------------------------------------------------------------
-- VUES POUR FACILITER LES REQUÊTES
-- ----------------------------------------------------------------------------

-- Vue des comptes partagés avec infos membres
CREATE VIEW shared_accounts_with_members AS
SELECT 
    sa.*,
    COUNT(sam.user_id) FILTER (WHERE sam.role != 'child') as adult_count,
    COUNT(sam.user_id) FILTER (WHERE sam.role = 'child') as child_count,
    jsonb_agg(
        jsonb_build_object(
            'user_id', sam.user_id,
            'role', sam.role,
            'display_name', sam.display_name,
            'avatar_url', sam.avatar_url,
            'joined_at', sam.joined_at
        )
    ) FILTER (WHERE sam.user_id IS NOT NULL) as members
FROM shared_accounts sa
LEFT JOIN shared_account_members sam ON sa.id = sam.shared_account_id
WHERE sa.status = 'active'
GROUP BY sa.id;

-- Vue des transactions avec infos créateur
CREATE VIEW shared_transactions_with_creator AS
SELECT 
    st.*,
    p.full_name as creator_name,
    p.avatar_url as creator_avatar
FROM shared_transactions st
LEFT JOIN profiles p ON st.created_by = p.id;

-- ----------------------------------------------------------------------------
-- COMMENTAIRES DE DOCUMENTATION
-- ----------------------------------------------------------------------------

COMMENT ON TABLE shared_accounts IS 'Comptes partagés entre utilisateurs (couple, famille, colocataires)';
COMMENT ON TABLE shared_account_members IS 'Membres et leurs permissions dans un compte partagé';
COMMENT ON TABLE shared_invitations IS 'Invitations envoyées pour rejoindre un compte partagé';
COMMENT ON TABLE shared_transactions IS 'Transactions liées à un compte partagé';
COMMENT ON TABLE shared_settlements IS 'Règlements entre membres d''un compte partagé';
