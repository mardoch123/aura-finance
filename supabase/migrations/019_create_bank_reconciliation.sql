-- ============================================================================
-- MIGRATION 019: Rapprochement Bancaire Intelligent
-- Import PDF, matching auto, détection écarts, reconciliation visuelle
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE: bank_statements
-- Relevés bancaires importés
-- ----------------------------------------------------------------------------
CREATE TABLE bank_statements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE NOT NULL,
    
    -- Période
    statement_period_start DATE NOT NULL,
    statement_period_end DATE NOT NULL,
    
    -- Fichier source
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL, -- Supabase Storage
    file_size INTEGER,
    
    -- Métadonnées extraites
    bank_name TEXT,
    account_number_masked TEXT, -- ****1234
    currency TEXT DEFAULT 'EUR',
    
    -- Soldes
    opening_balance DECIMAL(12,2) NOT NULL,
    closing_balance DECIMAL(12,2) NOT NULL,
    calculated_balance DECIMAL(12,2), -- Somme des transactions importées
    
    -- Statut
    status TEXT DEFAULT 'processing' CHECK(status IN ('processing', 'parsed', 'matching', 'reconciled', 'error')),
    
    -- Stats
    total_transactions INTEGER DEFAULT 0,
    matched_transactions INTEGER DEFAULT 0,
    unmatched_transactions INTEGER DEFAULT 0,
    discrepancy_amount DECIMAL(12,2) DEFAULT 0,
    
    -- Erreur
    error_message TEXT,
    
    -- Traitement
    processed_at TIMESTAMPTZ,
    processed_by TEXT, -- 'ai', 'manual', 'hybrid'
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_bank_statements_user ON bank_statements(user_id);
CREATE INDEX idx_bank_statements_account ON bank_statements(account_id);
CREATE INDEX idx_bank_statements_status ON bank_statements(status);
CREATE INDEX idx_bank_statements_period ON bank_statements(statement_period_start, statement_period_end);

-- ----------------------------------------------------------------------------
-- TABLE: bank_statement_transactions
-- Transactions extraites du relevé
-- ----------------------------------------------------------------------------
CREATE TABLE bank_statement_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    statement_id UUID REFERENCES bank_statements(id) ON DELETE CASCADE NOT NULL,
    
    -- Données brutes extraites
    raw_date TEXT,
    raw_description TEXT,
    raw_amount TEXT,
    raw_balance TEXT,
    
    -- Données parsées
    transaction_date DATE NOT NULL,
    value_date DATE,
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL, -- Négatif = débit, Positif = crédit
    
    -- Classification IA
    category TEXT,
    subcategory TEXT,
    merchant_name TEXT,
    merchant_id UUID,
    
    -- Référence
    reference_number TEXT,
    check_number TEXT,
    
    -- Matching
    matched_transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    match_confidence DECIMAL(3,2), -- 0.00 à 1.00
    match_method TEXT CHECK(match_method IN ('exact', 'fuzzy', 'manual', 'ai')),
    matched_at TIMESTAMPTZ,
    matched_by UUID REFERENCES profiles(id),
    
    -- Écart détecté
    has_discrepancy BOOLEAN DEFAULT FALSE,
    discrepancy_type TEXT CHECK(discrepancy_type IN ('amount', 'date', 'duplicate', 'missing', 'unknown')),
    discrepancy_details JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "expected_amount": -45.50,
    --   "actual_amount": -45.00,
    --   "expected_date": "2024-01-15",
    --   "actual_date": "2024-01-16"
    -- }
    
    -- Statut
    status TEXT DEFAULT 'unmatched' CHECK(status IN ('unmatched', 'matched', 'discrepancy', 'ignored', 'created')),
    
    -- Action utilisateur
    user_action TEXT CHECK(user_action IN ('confirm', 'create', 'ignore', 'merge')),
    user_action_at TIMESTAMPTZ,
    user_action_by UUID REFERENCES profiles(id),
    user_notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_bank_stmt_txn_statement ON bank_statement_transactions(statement_id);
CREATE INDEX idx_bank_stmt_txn_date ON bank_statement_transactions(transaction_date);
CREATE INDEX idx_bank_stmt_txn_status ON bank_statement_transactions(status);
CREATE INDEX idx_bank_stmt_txn_matched ON bank_statement_transactions(matched_transaction_id);
CREATE INDEX idx_bank_stmt_txn_discrepancy ON bank_statement_transactions(has_discrepancy) WHERE has_discrepancy = TRUE;
CREATE INDEX idx_bank_stmt_txn_description ON bank_statement_transactions USING gin(to_tsvector('french', description));

-- ----------------------------------------------------------------------------
-- TABLE: reconciliation_sessions
-- Sessions de rapprochement
-- ----------------------------------------------------------------------------
CREATE TABLE reconciliation_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE NOT NULL,
    statement_id UUID REFERENCES bank_statements(id) ON DELETE CASCADE,
    
    -- Période
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Progression
    total_items INTEGER DEFAULT 0,
    processed_items INTEGER DEFAULT 0,
    matched_items INTEGER DEFAULT 0,
    discrepancy_items INTEGER DEFAULT 0,
    
    -- Statut
    status TEXT DEFAULT 'in_progress' CHECK(status IN ('in_progress', 'paused', 'completed', 'abandoned')),
    
    -- Temps
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    
    -- Résultat
    starting_balance DECIMAL(12,2),
    ending_balance DECIMAL(12,2),
    discrepancy_total DECIMAL(12,2) DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reconciliation_sessions_user ON reconciliation_sessions(user_id);
CREATE INDEX idx_reconciliation_sessions_account ON reconciliation_sessions(account_id);
CREATE INDEX idx_reconciliation_sessions_status ON reconciliation_sessions(status);

-- ----------------------------------------------------------------------------
-- TABLE: reconciliation_actions
-- Log des actions de rapprochement
-- ----------------------------------------------------------------------------
CREATE TABLE reconciliation_actions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    session_id UUID REFERENCES reconciliation_sessions(id) ON DELETE CASCADE NOT NULL,
    
    -- Action
    action_type TEXT NOT NULL CHECK(action_type IN (
        'match',           -- Associer deux transactions
        'unmatch',         -- Dissocier
        'create',          -- Créer une nouvelle transaction
        'ignore',          -- Ignorer
        'edit',            -- Modifier une transaction existante
        'merge',           -- Fusionner des doublons
        'confirm_balance', -- Confirmer un solde
        'add_note'         -- Ajouter une note
    )),
    
    -- Entités concernées
    statement_transaction_id UUID REFERENCES bank_statement_transactions(id),
    app_transaction_id UUID REFERENCES transactions(id),
    
    -- Détails
    details JSONB DEFAULT '{}'::jsonb,
    
    -- Auteur
    performed_by UUID REFERENCES profiles(id) NOT NULL,
    performed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Undo
    can_undo BOOLEAN DEFAULT TRUE,
    undone_at TIMESTAMPTZ,
    undone_by UUID REFERENCES profiles(id)
);

CREATE INDEX idx_reconciliation_actions_session ON reconciliation_actions(session_id);
CREATE INDEX idx_reconciliation_actions_performed ON reconciliation_actions(performed_at);

-- ----------------------------------------------------------------------------
-- TABLE: matching_rules
-- Règles de matching personnalisées
-- ----------------------------------------------------------------------------
CREATE TABLE matching_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Pattern
    name TEXT NOT NULL,
    description TEXT,
    
    -- Conditions
    bank_description_pattern TEXT, -- Regex
    app_description_pattern TEXT,
    amount_tolerance DECIMAL(5,2) DEFAULT 0.01, -- 1% par défaut
    date_tolerance_days INTEGER DEFAULT 2,
    
    -- Action
    auto_match BOOLEAN DEFAULT FALSE,
    auto_categorize TEXT,
    
    -- Priorité
    priority INTEGER DEFAULT 0,
    
    -- Statistiques
    times_applied INTEGER DEFAULT 0,
    last_applied_at TIMESTAMPTZ,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_matching_rules_user ON matching_rules(user_id);
CREATE INDEX idx_matching_rules_active ON matching_rules(is_active) WHERE is_active = TRUE;

-- ----------------------------------------------------------------------------
-- FONCTION: Matcher automatiquement les transactions
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_match_transactions(p_statement_id UUID)
RETURNS TABLE (
    statement_txn_id UUID,
    matched_txn_id UUID,
    confidence DECIMAL,
    method TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_stmt_txn RECORD;
    v_match RECORD;
BEGIN
    FOR v_stmt_txn IN 
        SELECT * FROM bank_statement_transactions 
        WHERE statement_id = p_statement_id 
          AND status = 'unmatched'
    LOOP
        -- Recherche exacte (montant + date + description similaire)
        SELECT t.id INTO v_match
        FROM transactions t
        WHERE t.account_id = (SELECT account_id FROM bank_statements WHERE id = p_statement_id)
          AND t.amount = v_stmt_txn.amount
          AND ABS(EXTRACT(EPOCH FROM (t.date - v_stmt_txn.transaction_date))) <= 172800 -- 2 jours
          AND similarity(t.description, v_stmt_txn.description) > 0.7
          AND NOT EXISTS (
              SELECT 1 FROM bank_statement_transactions bst 
              WHERE bst.matched_transaction_id = t.id
          )
        ORDER BY similarity(t.description, v_stmt_txn.description) DESC
        LIMIT 1;
        
        IF FOUND THEN
            -- Mettre à jour le match
            UPDATE bank_statement_transactions
            SET 
                matched_transaction_id = v_match.id,
                match_confidence = 0.95,
                match_method = 'exact',
                matched_at = NOW(),
                status = 'matched'
            WHERE id = v_stmt_txn.id;
            
            statement_txn_id := v_stmt_txn.id;
            matched_txn_id := v_match.id;
            confidence := 0.95;
            method := 'exact';
            RETURN NEXT;
        ELSE
            -- Recherche fuzzy
            SELECT t.id INTO v_match
            FROM transactions t
            WHERE t.account_id = (SELECT account_id FROM bank_statements WHERE id = p_statement_id)
              AND ABS(t.amount - v_stmt_txn.amount) <= 0.05
              AND ABS(EXTRACT(EPOCH FROM (t.date - v_stmt_txn.transaction_date))) <= 604800 -- 7 jours
              AND NOT EXISTS (
                  SELECT 1 FROM bank_statement_transactions bst 
                  WHERE bst.matched_transaction_id = t.id
              )
            ORDER BY ABS(t.amount - v_stmt_txn.amount), 
                     ABS(EXTRACT(EPOCH FROM (t.date - v_stmt_txn.transaction_date)))
            LIMIT 1;
            
            IF FOUND THEN
                -- Écart potentiel
                UPDATE bank_statement_transactions
                SET 
                    matched_transaction_id = v_match.id,
                    match_confidence = 0.75,
                    match_method = 'fuzzy',
                    matched_at = NOW(),
                    status = 'discrepancy',
                    has_discrepancy = TRUE,
                    discrepancy_type = CASE 
                        WHEN ABS((SELECT amount FROM transactions WHERE id = v_match.id) - v_stmt_txn.amount) > 0.05 THEN 'amount'
                        ELSE 'date'
                    END,
                    discrepancy_details = jsonb_build_object(
                        'expected_amount', (SELECT amount FROM transactions WHERE id = v_match.id),
                        'actual_amount', v_stmt_txn.amount,
                        'expected_date', (SELECT date::date FROM transactions WHERE id = v_match.id),
                        'actual_date', v_stmt_txn.transaction_date
                    )
                WHERE id = v_stmt_txn.id;
                
                statement_txn_id := v_stmt_txn.id;
                matched_txn_id := v_match.id;
                confidence := 0.75;
                method := 'fuzzy';
                RETURN NEXT;
            END IF;
        END IF;
    END LOOP;
    
    RETURN;
END;
$$;

-- ----------------------------------------------------------------------------
-- FONCTION: Mettre à jour les stats du relevé
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_statement_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE bank_statements
    SET 
        total_transactions = (
            SELECT COUNT(*) FROM bank_statement_transactions WHERE statement_id = COALESCE(NEW.statement_id, OLD.statement_id)
        ),
        matched_transactions = (
            SELECT COUNT(*) FROM bank_statement_transactions 
            WHERE statement_id = COALESCE(NEW.statement_id, OLD.statement_id) 
              AND status = 'matched'
        ),
        unmatched_transactions = (
            SELECT COUNT(*) FROM bank_statement_transactions 
            WHERE statement_id = COALESCE(NEW.statement_id, OLD.statement_id) 
              AND status = 'unmatched'
        ),
        discrepancy_amount = (
            SELECT COALESCE(SUM(ABS(
                (SELECT amount FROM transactions WHERE id = matched_transaction_id) - amount
            )), 0)
            FROM bank_statement_transactions 
            WHERE statement_id = COALESCE(NEW.statement_id, OLD.statement_id) 
              AND has_discrepancy = TRUE
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.statement_id, OLD.statement_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trigger_update_statement_stats
    AFTER INSERT OR UPDATE OR DELETE ON bank_statement_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_statement_stats();

-- ----------------------------------------------------------------------------
-- RLS POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE bank_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_statement_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reconciliation_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reconciliation_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE matching_rules ENABLE ROW LEVEL SECURITY;

-- bank_statements
CREATE POLICY "Users can manage own statements"
    ON bank_statements FOR ALL
    USING (user_id = auth.uid());

-- bank_statement_transactions
CREATE POLICY "Users can view own statement transactions"
    ON bank_statement_transactions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM bank_statements bs
            WHERE bs.id = bank_statement_transactions.statement_id
              AND bs.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own statement transactions"
    ON bank_statement_transactions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM bank_statements bs
            WHERE bs.id = bank_statement_transactions.statement_id
              AND bs.user_id = auth.uid()
        )
    );

-- reconciliation_sessions
CREATE POLICY "Users can manage own reconciliation sessions"
    ON reconciliation_sessions FOR ALL
    USING (user_id = auth.uid());

-- matching_rules
CREATE POLICY "Users can manage own matching rules"
    ON matching_rules FOR ALL
    USING (user_id = auth.uid());