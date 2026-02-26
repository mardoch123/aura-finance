-- Migration: Création de la table transactions
-- Description: Table des transactions financières

-- ═══════════════════════════════════════════════════════════
-- TABLE: transactions
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    amount DECIMAL(12,2) NOT NULL,
    category TEXT DEFAULT 'other',
    subcategory TEXT,
    merchant TEXT,
    description TEXT,
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source TEXT DEFAULT 'manual' CHECK(source IN ('manual', 'scan', 'voice', 'import')),
    scan_image_url TEXT,
    ai_confidence DECIMAL(3,2) CHECK(ai_confidence >= 0 AND ai_confidence <= 1),
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_group_id UUID,
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_transactions_user_date 
ON transactions(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_transactions_user_category 
ON transactions(user_id, category);

CREATE INDEX IF NOT EXISTS idx_transactions_recurring 
ON transactions(is_recurring) WHERE is_recurring = TRUE;

CREATE INDEX IF NOT EXISTS idx_transactions_merchant 
ON transactions(merchant) WHERE merchant IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_date_range 
ON transactions(user_id, date) 
WHERE date >= NOW() - INTERVAL '90 days';

-- Index pour la recherche full-text
CREATE INDEX IF NOT EXISTS idx_transactions_search 
ON transactions USING gin(to_tsvector('french', COALESCE(description, '') || ' ' || COALESCE(merchant, '')));

-- ═══════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres transactions
CREATE POLICY "Users can view own transactions"
ON transactions FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent créer leurs propres transactions
CREATE POLICY "Users can create own transactions"
ON transactions FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent modifier leurs propres transactions
CREATE POLICY "Users can update own transactions"
ON transactions FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent supprimer leurs propres transactions
CREATE POLICY "Users can delete own transactions"
ON transactions FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════

CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour mettre à jour le solde du compte
CREATE OR REPLACE FUNCTION update_account_balance_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE accounts 
        SET balance = balance + NEW.amount
        WHERE id = NEW.account_id;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Annuler l'ancien montant
        UPDATE accounts 
        SET balance = balance - OLD.amount
        WHERE id = OLD.account_id;
        -- Appliquer le nouveau montant
        UPDATE accounts 
        SET balance = balance + NEW.amount
        WHERE id = NEW.account_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE accounts 
        SET balance = balance - OLD.amount
        WHERE id = OLD.account_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_account_balance
    AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance_on_transaction();

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS
-- ═══════════════════════════════════════════════════════════

-- Fonction pour obtenir les statistiques mensuelles
CREATE OR REPLACE FUNCTION get_monthly_stats(
    user_uuid UUID,
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    month DATE,
    total_income DECIMAL,
    total_expense DECIMAL,
    net_amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE_TRUNC('month', t.date)::DATE as month,
        COALESCE(SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END), 0) as total_expense,
        COALESCE(SUM(t.amount), 0) as net_amount
    FROM transactions t
    WHERE t.user_id = user_uuid
        AND t.date >= start_date
        AND t.date < end_date
    GROUP BY DATE_TRUNC('month', t.date)
    ORDER BY month;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les dépenses par catégorie
CREATE OR REPLACE FUNCTION get_expenses_by_category(
    user_uuid UUID,
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    category TEXT,
    total_amount DECIMAL,
    transaction_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.category,
        COALESCE(SUM(ABS(t.amount)), 0) as total_amount,
        COUNT(*) as transaction_count
    FROM transactions t
    WHERE t.user_id = user_uuid
        AND t.amount < 0
        AND t.date >= start_date
        AND t.date < end_date
    GROUP BY t.category
    ORDER BY total_amount DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON TABLE transactions IS 'Transactions financières des utilisateurs';
COMMENT ON COLUMN transactions.amount IS 'Montant: négatif = dépense, positif = revenu';
COMMENT ON COLUMN transactions.source IS 'Source: manual, scan, voice, import';
COMMENT ON COLUMN transactions.ai_confidence IS 'Confiance IA de 0.00 à 1.00';
