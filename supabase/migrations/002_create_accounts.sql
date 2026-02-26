-- Migration: Création de la table accounts
-- Description: Table des comptes bancaires de l'utilisateur

-- ═══════════════════════════════════════════════════════════
-- TABLE: accounts
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    type TEXT CHECK(type IN ('checking', 'savings', 'credit', 'investment')) DEFAULT 'checking',
    balance DECIMAL(12,2) DEFAULT 0,
    color TEXT DEFAULT '#E8A86C',
    institution TEXT,
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    account_number_masked TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(type);
CREATE INDEX IF NOT EXISTS idx_accounts_primary ON accounts(user_id, is_primary) WHERE is_primary = TRUE;

-- ═══════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres comptes
CREATE POLICY "Users can view own accounts"
ON accounts FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent créer leurs propres comptes
CREATE POLICY "Users can create own accounts"
ON accounts FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent modifier leurs propres comptes
CREATE POLICY "Users can update own accounts"
ON accounts FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent supprimer leurs propres comptes
CREATE POLICY "Users can delete own accounts"
ON accounts FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════

CREATE TRIGGER update_accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS
-- ═══════════════════════════════════════════════════════════

-- Fonction pour calculer le solde total d'un utilisateur
CREATE OR REPLACE FUNCTION get_user_total_balance(user_uuid UUID)
RETURNS DECIMAL AS $$
DECLARE
    total DECIMAL;
BEGIN
    SELECT COALESCE(SUM(balance), 0)
    INTO total
    FROM accounts
    WHERE user_id = user_uuid AND is_active = TRUE;
    
    RETURN total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON TABLE accounts IS 'Comptes bancaires des utilisateurs';
COMMENT ON COLUMN accounts.type IS 'Type: checking, savings, credit, investment';
COMMENT ON COLUMN accounts.is_primary IS 'Compte principal par défaut';
