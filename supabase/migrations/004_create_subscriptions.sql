-- Migration: Création de la table subscriptions
-- Description: Table des abonnements détectés et suivis

-- ═══════════════════════════════════════════════════════════
-- TABLE: subscriptions
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    previous_amount DECIMAL(12,2),
    billing_cycle TEXT CHECK(billing_cycle IN ('weekly', 'monthly', 'yearly')) DEFAULT 'monthly',
    next_billing_date DATE,
    category TEXT DEFAULT 'subscriptions',
    merchant_pattern TEXT,
    description TEXT,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_vampire BOOLEAN DEFAULT FALSE,
    price_increase_detected_at TIMESTAMPTZ,
    price_increase_percentage DECIMAL(5,2),
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_active ON subscriptions(user_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_subscriptions_vampire ON subscriptions(user_id, is_vampire) WHERE is_vampire = TRUE;
CREATE INDEX IF NOT EXISTS idx_subscriptions_next_billing ON subscriptions(next_billing_date);

-- ═══════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres abonnements
CREATE POLICY "Users can view own subscriptions"
ON subscriptions FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent créer leurs propres abonnements
CREATE POLICY "Users can create own subscriptions"
ON subscriptions FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent modifier leurs propres abonnements
CREATE POLICY "Users can update own subscriptions"
ON subscriptions FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent supprimer leurs propres abonnements
CREATE POLICY "Users can delete own subscriptions"
ON subscriptions FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour détecter les vampires (hausse de prix)
CREATE OR REPLACE FUNCTION detect_vampire_price_increase()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.previous_amount IS NOT NULL 
        AND NEW.previous_amount > 0 
        AND NEW.amount > NEW.previous_amount THEN
        NEW.is_vampire := TRUE;
        NEW.price_increase_detected_at := NOW();
        NEW.price_increase_percentage := 
            ROUND(((NEW.amount - NEW.previous_amount) / NEW.previous_amount * 100)::numeric, 2);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_vampire_price_increase
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION detect_vampire_price_increase();

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS
-- ═══════════════════════════════════════════════════════════

-- Fonction pour calculer le total mensuel des abonnements
CREATE OR REPLACE FUNCTION get_monthly_subscriptions_total(user_uuid UUID)
RETURNS DECIMAL AS $$
DECLARE
    total DECIMAL;
BEGIN
    SELECT COALESCE(SUM(
        CASE billing_cycle
            WHEN 'weekly' THEN amount * 4.33
            WHEN 'monthly' THEN amount
            WHEN 'yearly' THEN amount / 12
            ELSE amount
        END
    ), 0)
    INTO total
    FROM subscriptions
    WHERE user_id = user_uuid AND is_active = TRUE;
    
    RETURN total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les abonnements à venir
CREATE OR REPLACE FUNCTION get_upcoming_subscriptions(
    user_uuid UUID,
    days_ahead INTEGER DEFAULT 7
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    amount DECIMAL,
    billing_date DATE,
    days_until INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.name,
        s.amount,
        s.next_billing_date as billing_date,
        (s.next_billing_date - CURRENT_DATE)::INTEGER as days_until
    FROM subscriptions s
    WHERE s.user_id = user_uuid
        AND s.is_active = TRUE
        AND s.next_billing_date BETWEEN CURRENT_DATE AND CURRENT_DATE + days_ahead
    ORDER BY s.next_billing_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- VUE: Résumé des abonnements
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW subscription_summary AS
SELECT 
    s.user_id,
    COUNT(*) as total_subscriptions,
    COUNT(*) FILTER (WHERE s.is_vampire = TRUE) as vampire_count,
    SUM(CASE 
        WHEN s.billing_cycle = 'weekly' THEN s.amount * 4.33
        WHEN s.billing_cycle = 'monthly' THEN s.amount
        WHEN s.billing_cycle = 'yearly' THEN s.amount / 12
        ELSE s.amount
    END) as monthly_total,
    SUM(CASE 
        WHEN s.billing_cycle = 'yearly' THEN s.amount
        ELSE s.amount * 12
    END) as yearly_total
FROM subscriptions s
WHERE s.is_active = TRUE
GROUP BY s.user_id;

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON TABLE subscriptions IS 'Abonnements détectés et suivis';
COMMENT ON COLUMN subscriptions.is_vampire IS 'TRUE si une hausse de prix a été détectée';
COMMENT ON COLUMN subscriptions.merchant_pattern IS 'Pattern regex pour auto-détecter dans les transactions';
COMMENT ON COLUMN subscriptions.price_increase_percentage IS 'Pourcentage d augmentation du prix';
