-- ============================================================================
-- MIGRATION 018: Détection de Voyage & Mode Vacances
-- Multi-devises, budget voyage, split dépenses groupe
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE: user_trips
-- Voyages détectés ou créés manuellement
-- ----------------------------------------------------------------------------
CREATE TABLE user_trips (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Informations du voyage
    name TEXT NOT NULL, -- ex: "Week-end Lisbonne", "Vacances Été 2024"
    destination_country TEXT NOT NULL,
    destination_city TEXT,
    destination_currency TEXT NOT NULL, -- ISO code: USD, GBP, JPY...
    
    -- Dates
    start_date DATE NOT NULL,
    end_date DATE,
    is_ongoing BOOLEAN DEFAULT TRUE,
    
    -- Budget
    total_budget DECIMAL(12,2),
    daily_budget DECIMAL(12,2), -- Calculé automatiquement
    spent_amount DECIMAL(12,2) DEFAULT 0,
    
    -- Détection automatique
    detected_at TIMESTAMPTZ,
    detection_source TEXT CHECK(detection_source IN ('gps', 'transaction_pattern', 'manual', 'calendar')),
    
    -- Groupe / Partage
    is_group_trip BOOLEAN DEFAULT FALSE,
    group_code TEXT UNIQUE, -- Code pour rejoindre le voyage
    
    -- Statut
    status TEXT DEFAULT 'upcoming' CHECK(status IN ('upcoming', 'active', 'completed', 'cancelled')),
    
    -- Métadonnées
    metadata JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "home_currency_rate": 1.08,
    --   "weather_at_arrival": "sunny",
    --   "flight_number": "AF1234"
    -- }
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_trips_user ON user_trips(user_id);
CREATE INDEX idx_user_trips_status ON user_trips(status);
CREATE INDEX idx_user_trips_ongoing ON user_trips(user_id, is_ongoing) WHERE is_ongoing = TRUE;
CREATE INDEX idx_user_trips_dates ON user_trips(start_date, end_date);
CREATE INDEX idx_user_trips_group_code ON user_trips(group_code) WHERE group_code IS NOT NULL;

-- ----------------------------------------------------------------------------
-- TABLE: trip_members
-- Membres d'un voyage de groupe
-- ----------------------------------------------------------------------------
CREATE TABLE trip_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    trip_id UUID REFERENCES user_trips(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Rôle
    role TEXT DEFAULT 'member' CHECK(role IN ('owner', 'admin', 'member')),
    
    -- Invitation
    invited_by UUID REFERENCES profiles(id),
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    joined_at TIMESTAMPTZ,
    
    -- Statut
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'joined', 'declined', 'removed')),
    
    -- Solde (qui doit quoi à qui)
    balance DECIMAL(12,2) DEFAULT 0, -- Positif = on lui doit, Négatif = il doit
    
    UNIQUE(trip_id, user_id)
);

CREATE INDEX idx_trip_members_trip ON trip_members(trip_id);
CREATE INDEX idx_trip_members_user ON trip_members(user_id);
CREATE INDEX idx_trip_members_status ON trip_members(status);

-- ----------------------------------------------------------------------------
-- TABLE: trip_expenses
-- Dépenses partagées d'un voyage
-- ----------------------------------------------------------------------------
CREATE TABLE trip_expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    trip_id UUID REFERENCES user_trips(id) ON DELETE CASCADE NOT NULL,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    
    -- Payeur
    paid_by UUID REFERENCES profiles(id) NOT NULL,
    
    -- Détails
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',
    
    -- Date
    expense_date DATE NOT NULL,
    
    -- Catégorie
    category TEXT,
    
    -- Répartition
    split_type TEXT DEFAULT 'equal' CHECK(split_type IN ('equal', 'percentage', 'amount', 'shares')),
    split_details JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "splits": [
    --     {"user_id": "uuid", "amount": 25.00, "percentage": 50},
    --     {"user_id": "uuid", "amount": 25.00, "percentage": 50}
    --   ]
    -- }
    
    -- Photo/Justificatif
    receipt_url TEXT,
    
    -- Notes
    notes TEXT,
    
    -- Statut
    is_settled BOOLEAN DEFAULT FALSE,
    settled_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trip_expenses_trip ON trip_expenses(trip_id);
CREATE INDEX idx_trip_expenses_paid_by ON trip_expenses(paid_by);
CREATE INDEX idx_trip_expenses_date ON trip_expenses(expense_date);
CREATE INDEX idx_trip_expenses_settled ON trip_expenses(is_settled) WHERE is_settled = FALSE;

-- ----------------------------------------------------------------------------
-- TABLE: trip_expense_participants
-- Qui participe à quelle dépense
-- ----------------------------------------------------------------------------
CREATE TABLE trip_expense_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    expense_id UUID REFERENCES trip_expenses(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Montant dû par cette personne
    share_amount DECIMAL(12,2) NOT NULL,
    share_percentage DECIMAL(5,2),
    
    -- Statut
    is_paid BOOLEAN DEFAULT FALSE,
    paid_at TIMESTAMPTZ,
    
    UNIQUE(expense_id, user_id)
);

CREATE INDEX idx_trip_expense_participants_expense ON trip_expense_participants(expense_id);
CREATE INDEX idx_trip_expense_participants_user ON trip_expense_participants(user_id);

-- ----------------------------------------------------------------------------
-- TABLE: trip_settlements
-- Règlements entre membres
-- ----------------------------------------------------------------------------
CREATE TABLE trip_settlements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    trip_id UUID REFERENCES user_trips(id) ON DELETE CASCADE NOT NULL,
    
    -- Qui paie qui
    from_user_id UUID REFERENCES profiles(id) NOT NULL, -- Celui qui doit
    to_user_id UUID REFERENCES profiles(id) NOT NULL,   -- Celui qui reçoit
    
    -- Montant
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',
    
    -- Méthode
    method TEXT CHECK(method IN ('cash', 'bank_transfer', 'paypal', 'revolut', ' Lydia', 'other')),
    
    -- Référence
    reference TEXT,
    
    -- Statut
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'completed', 'cancelled')),
    
    -- Dates
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trip_settlements_trip ON trip_settlements(trip_id);
CREATE INDEX idx_trip_settlements_from ON trip_settlements(from_user_id);
CREATE INDEX idx_trip_settlements_to ON trip_settlements(to_user_id);
CREATE INDEX idx_trip_settlements_status ON trip_settlements(status);

-- ----------------------------------------------------------------------------
-- TABLE: currency_rates
-- Taux de change historiques
-- ----------------------------------------------------------------------------
CREATE TABLE currency_rates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    from_currency TEXT NOT NULL,
    to_currency TEXT NOT NULL,
    rate DECIMAL(15,8) NOT NULL,
    
    -- Source et date
    source TEXT DEFAULT 'ECB', -- European Central Bank
    rate_date DATE NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(from_currency, to_currency, rate_date)
);

CREATE INDEX idx_currency_rates_lookup ON currency_rates(from_currency, to_currency, rate_date);

-- ----------------------------------------------------------------------------
-- TABLE: geo_locations
-- Historique des positions GPS (anonymisé)
-- ----------------------------------------------------------------------------
CREATE TABLE geo_locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Position
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    accuracy DECIMAL(8,2),
    
    -- Pays détecté
    country_code TEXT,
    city TEXT,
    
    -- Contexte
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    detection_source TEXT DEFAULT 'gps' CHECK(detection_source IN ('gps', 'ip', 'wifi', 'manual')),
    
    -- Anonymisation après 30 jours
    is_anonymized BOOLEAN DEFAULT FALSE,
    anonymized_at TIMESTAMPTZ
);

CREATE INDEX idx_geo_locations_user ON geo_locations(user_id);
CREATE INDEX idx_geo_locations_detected ON geo_locations(detected_at);
CREATE INDEX idx_geo_locations_country ON geo_locations(country_code);

-- ----------------------------------------------------------------------------
-- FONCTION: Détecter un voyage
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION detect_trip_from_transaction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_last_location RECORD;
    v_country TEXT;
    v_currency TEXT;
BEGIN
    -- Récupérer la dernière position connue
    SELECT country_code INTO v_country
    FROM geo_locations
    WHERE user_id = NEW.user_id
    ORDER BY detected_at DESC
    LIMIT 1;
    
    -- Si le pays de la transaction diffère du pays habituel (FR par défaut)
    -- ET qu'il n'y a pas de voyage actif
    IF v_country IS NOT NULL AND v_country != 'FR' THEN
        -- Vérifier s'il y a déjà un voyage actif
        IF NOT EXISTS (
            SELECT 1 FROM user_trips 
            WHERE user_id = NEW.user_id 
              AND is_ongoing = TRUE 
              AND destination_country = v_country
        ) THEN
            -- Déterminer la devise
            v_currency := CASE v_country
                WHEN 'US' THEN 'USD'
                WHEN 'GB' THEN 'GBP'
                WHEN 'JP' THEN 'JPY'
                WHEN 'CH' THEN 'CHF'
                WHEN 'CA' THEN 'CAD'
                ELSE 'EUR'
            END;
            
            -- Créer un voyage automatique
            INSERT INTO user_trips (
                user_id, name, destination_country, destination_currency,
                start_date, is_ongoing, detected_at, detection_source
            ) VALUES (
                NEW.user_id,
                'Voyage ' || v_country,
                v_country,
                v_currency,
                CURRENT_DATE,
                TRUE,
                NOW(),
                'transaction_pattern'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Trigger sur les transactions
CREATE TRIGGER trigger_detect_trip
    AFTER INSERT ON transactions
    FOR EACH ROW
    WHEN (NEW.source = 'manual' OR NEW.source = 'scan')
    EXECUTE FUNCTION detect_trip_from_transaction();

-- ----------------------------------------------------------------------------
-- FONCTION: Calculer les soldes d'un voyage
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_trip_balances(p_trip_id UUID)
RETURNS TABLE (user_id UUID, balance DECIMAL)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH expense_shares AS (
        -- Ce que chacun DOIT payer
        SELECT 
            tep.user_id,
            SUM(tep.share_amount) as owed
        FROM trip_expense_participants tep
        JOIN trip_expenses te ON tep.expense_id = te.id
        WHERE te.trip_id = p_trip_id
        GROUP BY tep.user_id
    ),
    amounts_paid AS (
        -- Ce que chacun A payé
        SELECT 
            paid_by as user_id,
            SUM(amount) as paid
        FROM trip_expenses
        WHERE trip_id = p_trip_id
        GROUP BY paid_by
    )
    SELECT 
        COALESCE(es.user_id, ap.user_id),
        COALESCE(ap.paid, 0) - COALESCE(es.owed, 0) as balance
    FROM expense_shares es
    FULL OUTER JOIN amounts_paid ap ON es.user_id = ap.user_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- RLS POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE user_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_expense_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE geo_locations ENABLE ROW LEVEL SECURITY;

-- user_trips: créateur + membres
CREATE POLICY "Users can view own trips"
    ON user_trips FOR SELECT
    USING (
        user_id = auth.uid() 
        OR EXISTS (
            SELECT 1 FROM trip_members 
            WHERE trip_id = user_trips.id 
              AND user_id = auth.uid() 
              AND status = 'joined'
        )
    );

CREATE POLICY "Users can create own trips"
    ON user_trips FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own trips"
    ON user_trips FOR UPDATE
    USING (user_id = auth.uid());

-- trip_members
CREATE POLICY "Trip members are viewable by trip participants"
    ON trip_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_trips ut
            LEFT JOIN trip_members tm ON ut.id = tm.trip_id AND tm.user_id = auth.uid()
            WHERE ut.id = trip_members.trip_id
              AND (ut.user_id = auth.uid() OR tm.user_id = auth.uid())
        )
    );

-- trip_expenses
CREATE POLICY "Trip expenses viewable by participants"
    ON trip_expenses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_trips ut
            LEFT JOIN trip_members tm ON ut.id = tm.trip_id AND tm.user_id = auth.uid()
            WHERE ut.id = trip_expenses.trip_id
              AND (ut.user_id = auth.uid() OR tm.user_id = auth.uid())
        )
    );

-- geo_locations: uniquement son propre historique
CREATE POLICY "Users can view own locations"
    ON geo_locations FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own locations"
    ON geo_locations FOR INSERT
    WITH CHECK (user_id = auth.uid());