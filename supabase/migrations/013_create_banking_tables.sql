-- ═══════════════════════════════════════════════════════════
-- TABLE: Comptes bancaires connectés (Open Banking)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE connected_bank_accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Institution bancaire
    institution_id TEXT NOT NULL,
    institution_name TEXT NOT NULL,
    logo_url TEXT,
    
    -- Compte
    account_id TEXT NOT NULL, -- ID chez le provider
    account_name TEXT NOT NULL,
    account_type TEXT CHECK(account_type IN ('checking', 'savings', 'credit_card', 'loan', 'investment', 'unknown')),
    currency TEXT DEFAULT 'EUR',
    iban TEXT,
    
    -- Soldes
    current_balance DECIMAL(12,2),
    available_balance DECIMAL(12,2),
    
    -- Connexion
    provider TEXT NOT NULL CHECK(provider IN ('bridge', 'truelayer', 'plaid')),
    provider_connection_id TEXT, -- Token ou ID de connexion
    provider_refresh_token TEXT,
    token_expires_at TIMESTAMPTZ,
    
    -- Statut
    connection_status TEXT DEFAULT 'connected' CHECK(connection_status IN ('pending', 'connected', 'expired', 'error', 'disconnected')),
    last_sync_at TIMESTAMPTZ,
    last_error TEXT,
    
    -- Préférences
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    auto_sync_enabled BOOLEAN DEFAULT TRUE,
    sync_frequency_minutes INTEGER DEFAULT 360, -- 6 heures par défaut
    
    -- Métadonnées
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contrainte unique
    UNIQUE(user_id, account_id, provider)
);

-- Index pour les requêtes fréquentes
CREATE INDEX idx_connected_accounts_user ON connected_bank_accounts(user_id);
CREATE INDEX idx_connected_accounts_status ON connected_bank_accounts(connection_status) WHERE is_active = TRUE;
CREATE INDEX idx_connected_accounts_sync ON connected_bank_accounts(last_sync_at) WHERE auto_sync_enabled = TRUE;

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION update_connected_bank_accounts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_connected_bank_accounts_updated_at
    BEFORE UPDATE ON connected_bank_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_connected_bank_accounts_updated_at();

-- ═══════════════════════════════════════════════════════════
-- TABLE: Transactions bancaires importées
-- ═══════════════════════════════════════════════════════════

CREATE TABLE bank_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    account_id UUID REFERENCES connected_bank_accounts(id) ON DELETE CASCADE NOT NULL,
    
    -- Identifiants externes
    external_id TEXT NOT NULL, -- ID chez la banque
    internal_transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    
    -- Données transaction
    transaction_date TIMESTAMPTZ NOT NULL,
    booking_date TIMESTAMPTZ,
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    
    -- Description
    description TEXT NOT NULL,
    raw_description TEXT, -- Description brute de la banque
    counterparty_name TEXT,
    counterparty_account TEXT,
    reference TEXT,
    
    -- Catégorisation IA
    suggested_category TEXT,
    suggested_subcategory TEXT,
    categorization_confidence DECIMAL(3,2), -- 0.00 à 1.00
    is_categorized BOOLEAN DEFAULT FALSE,
    
    -- Détection de doublons
    is_duplicate BOOLEAN DEFAULT FALSE,
    duplicate_of_id UUID REFERENCES bank_transactions(id),
    duplicate_confidence DECIMAL(3,2),
    
    -- Statut
    status TEXT DEFAULT 'imported' CHECK(status IN ('imported', 'processed', 'ignored', 'error')),
    source TEXT DEFAULT 'banking' CHECK(source IN ('banking', 'manual', 'file_import')),
    
    -- Métadonnées
    imported_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    metadata JSONB, -- Données brutes du provider
    
    -- Contrainte unique
    UNIQUE(user_id, account_id, external_id)
);

-- Index optimisés
CREATE INDEX idx_bank_transactions_user ON bank_transactions(user_id);
CREATE INDEX idx_bank_transactions_account ON bank_transactions(account_id);
CREATE INDEX idx_bank_transactions_date ON bank_transactions(transaction_date DESC);
CREATE INDEX idx_bank_transactions_external ON bank_transactions(external_id);
CREATE INDEX idx_bank_transactions_duplicate ON bank_transactions(is_duplicate) WHERE is_duplicate = FALSE;
CREATE INDEX idx_bank_transactions_uncategorized ON bank_transactions(is_categorized) WHERE is_categorized = FALSE;

-- Index pour recherche de doublons
CREATE INDEX idx_bank_transactions_duplicate_check 
ON bank_transactions(user_id, amount, transaction_date) 
WHERE is_duplicate = FALSE;

-- ═══════════════════════════════════════════════════════════
-- TABLE: Catégories de marchands (base de connaissances)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE merchant_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    normalized_name TEXT NOT NULL,
    
    -- Catégorisation
    category TEXT NOT NULL,
    subcategory TEXT,
    
    -- Métadonnées
    logo_url TEXT,
    website TEXT,
    
    -- Statistiques
    usage_count INTEGER DEFAULT 1,
    user_confirmed BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_merchant_categories_name ON merchant_categories(normalized_name);
CREATE INDEX idx_merchant_categories_category ON merchant_categories(category);

-- Données initiales pour les marchands populaires en France
INSERT INTO merchant_categories (name, normalized_name, category, subcategory, user_confirmed) VALUES
('McDonalds', 'mcdonalds', 'food', 'fast_food', TRUE),
('Burger King', 'burger king', 'food', 'fast_food', TRUE),
('KFC', 'kfc', 'food', 'fast_food', TRUE),
('Quick', 'quick', 'food', 'fast_food', TRUE),
('Subway', 'subway', 'food', 'fast_food', TRUE),
('Starbucks', 'starbucks', 'food', 'coffee', TRUE),
('Costa Coffee', 'costa coffee', 'food', 'coffee', TRUE),

('Carrefour', 'carrefour', 'food', 'groceries', TRUE),
('Auchan', 'auchan', 'food', 'groceries', TRUE),
('Leclerc', 'leclerc', 'food', 'groceries', TRUE),
('Lidl', 'lidl', 'food', 'groceries', TRUE),
('Aldi', 'aldi', 'food', 'groceries', TRUE),
('Monoprix', 'monoprix', 'food', 'groceries', TRUE),
('Franprix', 'franprix', 'food', 'groceries', TRUE),
('Casino', 'casino', 'food', 'groceries', TRUE),
('Intermarché', 'intermarche', 'food', 'groceries', TRUE),

('Uber', 'uber', 'transport', 'taxi', TRUE),
('Uber Eats', 'uber eats', 'food', 'delivery', TRUE),
('Bolt', 'bolt', 'transport', 'taxi', TRUE),
('SNCF', 'sncf', 'transport', 'train', TRUE),
('RATP', 'ratp', 'transport', 'public', TRUE),
('Total', 'total', 'transport', 'fuel', TRUE),
('Shell', 'shell', 'transport', 'fuel', TRUE),
('BP', 'bp', 'transport', 'fuel', TRUE),

('Amazon', 'amazon', 'shopping', 'online', TRUE),
('Amazon Prime', 'amazon prime', 'subscriptions', 'streaming', TRUE),
('Fnac', 'fnac', 'shopping', 'electronics', TRUE),
('Darty', 'darty', 'shopping', 'electronics', TRUE),
('Boulanger', 'boulanger', 'shopping', 'electronics', TRUE),
('Cdiscount', 'cdiscount', 'shopping', 'online', TRUE),
('Zalando', 'zalando', 'shopping', 'clothing', TRUE),
('Zara', 'zara', 'shopping', 'clothing', TRUE),
('H&M', 'h&m', 'shopping', 'clothing', TRUE),
('Uniqlo', 'uniqlo', 'shopping', 'clothing', TRUE),
('Nike', 'nike', 'shopping', 'clothing', TRUE),
('Adidas', 'adidas', 'shopping', 'clothing', TRUE),
('Decathlon', 'decathlon', 'shopping', 'sports', TRUE),

('Netflix', 'netflix', 'subscriptions', 'streaming', TRUE),
('Spotify', 'spotify', 'subscriptions', 'music', TRUE),
('Disney+', 'disney+', 'subscriptions', 'streaming', TRUE),
('YouTube Premium', 'youtube premium', 'subscriptions', 'streaming', TRUE),
('Canal+', 'canal+', 'subscriptions', 'tv', TRUE),
('Apple Music', 'apple music', 'subscriptions', 'music', TRUE),
('Apple TV+', 'apple tv+', 'subscriptions', 'streaming', TRUE),

('Orange', 'orange', 'subscriptions', 'telecom', TRUE),
('SFR', 'sfr', 'subscriptions', 'telecom', TRUE),
('Bouygues Telecom', 'bouygues telecom', 'subscriptions', 'telecom', TRUE),
('Free', 'free', 'subscriptions', 'telecom', TRUE),

('EDF', 'edf', 'housing', 'energy', TRUE),
('Engie', 'engie', 'housing', 'energy', TRUE),
('TotalEnergies', 'totalenergies', 'housing', 'energy', TRUE),

('Booking.com', 'booking.com', 'entertainment', 'travel', TRUE),
('Airbnb', 'airbnb', 'entertainment', 'travel', TRUE),
('Hotels.com', 'hotels.com', 'entertainment', 'travel', TRUE),

('Pharmacie', 'pharmacie', 'health', 'pharmacy', TRUE),
('Doctolib', 'doctolib', 'health', 'medical', TRUE);

-- ═══════════════════════════════════════════════════════════
-- TABLE: Corrections utilisateur (apprentissage)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE user_category_corrections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
    merchant_name TEXT,
    
    original_category TEXT NOT NULL,
    corrected_category TEXT NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_corrections_user ON user_category_corrections(user_id);
CREATE INDEX idx_user_corrections_merchant ON user_category_corrections(merchant_name);

-- ═══════════════════════════════════════════════════════════
-- TABLE: Historique de synchronisation
-- ═══════════════════════════════════════════════════════════

CREATE TABLE sync_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    account_id UUID REFERENCES connected_bank_accounts(id) ON DELETE CASCADE,
    
    -- Résultats
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    transactions_imported INTEGER DEFAULT 0,
    transactions_updated INTEGER DEFAULT 0,
    duplicates_detected INTEGER DEFAULT 0,
    categorized_by_ai INTEGER DEFAULT 0,
    
    status TEXT DEFAULT 'running' CHECK(status IN ('running', 'completed', 'failed', 'partial')),
    error_message TEXT,
    warnings TEXT[],
    
    -- Métadonnées
    provider TEXT,
    raw_response JSONB
);

CREATE INDEX idx_sync_history_user ON sync_history(user_id);
CREATE INDEX idx_sync_history_account ON sync_history(account_id);
CREATE INDEX idx_sync_history_date ON sync_history(started_at DESC);

-- ═══════════════════════════════════════════════════════════
-- FONCTION: Détection de doublons
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION find_duplicate_transactions(
    p_user_id UUID,
    p_amount DECIMAL,
    p_date DATE,
    p_description TEXT,
    p_tolerance_days INTEGER DEFAULT 3,
    p_tolerance_amount DECIMAL DEFAULT 0.01
)
RETURNS TABLE (
    transaction_id UUID,
    similarity_score DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bt.id as transaction_id,
        (
            -- Score basé sur la date (30%)
            CASE 
                WHEN bt.transaction_date::DATE = p_date THEN 0.3
                WHEN ABS((bt.transaction_date::DATE - p_date)) <= 1 THEN 0.2
                WHEN ABS((bt.transaction_date::DATE - p_date)) <= p_tolerance_days THEN 0.1
                ELSE 0
            END +
            -- Score basé sur le montant (40%)
            CASE 
                WHEN ABS(bt.amount - p_amount) < p_tolerance_amount THEN 0.4
                WHEN ABS(bt.amount - p_amount) < 1.0 THEN 0.3
                ELSE 0
            END +
            -- Score basé sur la description (30%)
            CASE 
                WHEN bt.description ILIKE '%' || p_description || '%' THEN 0.3
                WHEN similarity(bt.description, p_description) > 0.8 THEN 0.25
                WHEN similarity(bt.description, p_description) > 0.6 THEN 0.15
                ELSE 0
            END
        )::DECIMAL as similarity_score
    FROM bank_transactions bt
    WHERE bt.user_id = p_user_id
      AND bt.is_duplicate = FALSE
      AND bt.transaction_date::DATE BETWEEN (p_date - p_tolerance_days) AND (p_date + p_tolerance_days)
      AND ABS(bt.amount - p_amount) < 5.0 -- Filtre rapide
    HAVING (
        CASE 
            WHEN bt.transaction_date::DATE = p_date THEN 0.3
            WHEN ABS((bt.transaction_date::DATE - p_date)) <= 1 THEN 0.2
            WHEN ABS((bt.transaction_date::DATE - p_date)) <= p_tolerance_days THEN 0.1
            ELSE 0
        END +
        CASE 
            WHEN ABS(bt.amount - p_amount) < p_tolerance_amount THEN 0.4
            WHEN ABS(bt.amount - p_amount) < 1.0 THEN 0.3
            ELSE 0
        END +
        CASE 
            WHEN bt.description ILIKE '%' || p_description || '%' THEN 0.3
            WHEN similarity(bt.description, p_description) > 0.8 THEN 0.25
            WHEN similarity(bt.description, p_description) > 0.6 THEN 0.15
            ELSE 0
        END
    ) > 0.7 -- Seuil minimum
    ORDER BY similarity_score DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════
-- FONCTION: Recherche d'abonnements en double
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION find_duplicate_subscriptions(
    p_user_id UUID
)
RETURNS TABLE (
    merchant_name TEXT,
    amount DECIMAL,
    occurrence_count INTEGER,
    first_date DATE,
    last_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bt.counterparty_name as merchant_name,
        ABS(bt.amount) as amount,
        COUNT(*)::INTEGER as occurrence_count,
        MIN(bt.transaction_date::DATE) as first_date,
        MAX(bt.transaction_date::DATE) as last_date
    FROM bank_transactions bt
    WHERE bt.user_id = p_user_id
      AND bt.is_duplicate = FALSE
      AND bt.transaction_date > NOW() - INTERVAL '90 days'
      AND ABS(bt.amount) > 5.0
    GROUP BY bt.counterparty_name, ABS(bt.amount)
    HAVING COUNT(*) >= 2
    ORDER BY COUNT(*) DESC, ABS(bt.amount) DESC;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════
-- RLS (Row Level Security)
-- ═══════════════════════════════════════════════════════════

ALTER TABLE connected_bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchant_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_category_corrections ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_history ENABLE ROW LEVEL SECURITY;

-- Politiques pour connected_bank_accounts
CREATE POLICY "Users can only see their own bank accounts"
    ON connected_bank_accounts FOR ALL
    USING (user_id = auth.uid());

-- Politiques pour bank_transactions
CREATE POLICY "Users can only see their own bank transactions"
    ON bank_transactions FOR ALL
    USING (user_id = auth.uid());

-- Politiques pour merchant_categories (lecture publique)
CREATE POLICY "Merchant categories are readable by all"
    ON merchant_categories FOR SELECT
    USING (TRUE);

CREATE POLICY "Only admins can modify merchant categories"
    ON merchant_categories FOR ALL
    USING (auth.jwt() ->> 'role' = 'admin');

-- Politiques pour user_category_corrections
CREATE POLICY "Users can only see their own corrections"
    ON user_category_corrections FOR ALL
    USING (user_id = auth.uid());

-- Politiques pour sync_history
CREATE POLICY "Users can only see their own sync history"
    ON sync_history FOR ALL
    USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════
-- TRIGGER: Mise à jour automatique des soldes
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_account_balance_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
    -- Mettre à jour le solde du compte connecté
    UPDATE connected_bank_accounts
    SET 
        current_balance = current_balance + NEW.amount,
        updated_at = NOW()
    WHERE id = NEW.account_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_balance_on_bank_transaction
    AFTER INSERT ON bank_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance_on_transaction();
