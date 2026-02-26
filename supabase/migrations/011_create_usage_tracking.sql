-- Migration: Création de la table usage_tracking
-- Description: Suivi détaillé de l'usage des features freemium

-- ═══════════════════════════════════════════════════════════
-- TABLE: usage_tracking
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS usage_tracking (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    month_year TEXT NOT NULL,  -- Format: '2025-07'
    
    -- Compteurs d'usage
    scan_count INT DEFAULT 0,
    coach_message_count INT DEFAULT 0,
    
    -- Bonus via rewarded ads
    scan_bonus INT DEFAULT 0,
    coach_bonus INT DEFAULT 0,
    bonus_expires_at TIMESTAMPTZ,  -- Expire à minuit
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contrainte d'unicité: un seul enregistrement par user/mois
    UNIQUE(user_id, month_year)
);

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_usage_tracking_user 
ON usage_tracking(user_id);

CREATE INDEX IF NOT EXISTS idx_usage_tracking_month 
ON usage_tracking(month_year);

CREATE INDEX IF NOT EXISTS idx_usage_tracking_user_month 
ON usage_tracking(user_id, month_year);

-- ═══════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════

ALTER TABLE usage_tracking ENABLE ROW LEVEL SECURITY;

-- Policy: Lecture uniquement par le propriétaire
CREATE POLICY "Users can view own usage"
ON usage_tracking FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Modification uniquement par le propriétaire
CREATE POLICY "Users can update own usage"
ON usage_tracking FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Insertion uniquement par le propriétaire
CREATE POLICY "Users can insert own usage"
ON usage_tracking FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS
-- ═══════════════════════════════════════════════════════════

-- Fonction: Récupérer ou créer l'usage du mois courant
CREATE OR REPLACE FUNCTION get_or_create_usage(p_user_id UUID)
RETURNS usage_tracking AS $$
DECLARE
    v_month_year TEXT;
    v_usage usage_tracking;
BEGIN
    v_month_year := TO_CHAR(NOW(), 'YYYY-MM');
    
    -- Essayer de récupérer l'usage existant
    SELECT * INTO v_usage
    FROM usage_tracking
    WHERE user_id = p_user_id AND month_year = v_month_year;
    
    -- Si pas trouvé, créer
    IF NOT FOUND THEN
        INSERT INTO usage_tracking (user_id, month_year)
        VALUES (p_user_id, v_month_year)
        RETURNING * INTO v_usage;
    END IF;
    
    RETURN v_usage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction: Incrémenter le compteur de scans
CREATE OR REPLACE FUNCTION increment_scan_count(p_user_id UUID)
RETURNS usage_tracking AS $$
DECLARE
    v_usage usage_tracking;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    -- Récupérer ou créer l'usage
    v_usage := get_or_create_usage(p_user_id);
    
    -- Vérifier si les bonus ont expiré
    IF v_usage.bonus_expires_at IS NOT NULL AND v_usage.bonus_expires_at < v_now THEN
        -- Bonus expirés, réinitialiser
        UPDATE usage_tracking
        SET scan_bonus = 0,
            coach_bonus = 0,
            bonus_expires_at = NULL,
            scan_count = scan_count + 1,
            updated_at = v_now
        WHERE id = v_usage.id
        RETURNING * INTO v_usage;
    ELSE
        -- Incrémenter normalement
        UPDATE usage_tracking
        SET scan_count = scan_count + 1,
            updated_at = v_now
        WHERE id = v_usage.id
        RETURNING * INTO v_usage;
    END IF;
    
    RETURN v_usage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction: Incrémenter le compteur de messages Coach
CREATE OR REPLACE FUNCTION increment_coach_count(p_user_id UUID)
RETURNS usage_tracking AS $$
DECLARE
    v_usage usage_tracking;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    v_usage := get_or_create_usage(p_user_id);
    
    -- Vérifier si les bonus ont expiré
    IF v_usage.bonus_expires_at IS NOT NULL AND v_usage.bonus_expires_at < v_now THEN
        UPDATE usage_tracking
        SET coach_bonus = 0,
            scan_bonus = 0,
            bonus_expires_at = NULL,
            coach_message_count = coach_message_count + 1,
            updated_at = v_now
        WHERE id = v_usage.id
        RETURNING * INTO v_usage;
    ELSE
        UPDATE usage_tracking
        SET coach_message_count = coach_message_count + 1,
            updated_at = v_now
        WHERE id = v_usage.id
        RETURNING * INTO v_usage;
    END IF;
    
    RETURN v_usage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction: Ajouter des bonus (appelée après pub récompensée)
CREATE OR REPLACE FUNCTION add_usage_bonus(
    p_user_id UUID,
    p_scan_bonus INT DEFAULT 0,
    p_coach_bonus INT DEFAULT 0
)
RETURNS usage_tracking AS $$
DECLARE
    v_usage usage_tracking;
    v_expires TIMESTAMPTZ;
BEGIN
    v_expires := DATE_TRUNC('day', NOW()) + INTERVAL '1 day' - INTERVAL '1 second';
    v_usage := get_or_create_usage(p_user_id);
    
    UPDATE usage_tracking
    SET scan_bonus = scan_bonus + p_scan_bonus,
        coach_bonus = coach_bonus + p_coach_bonus,
        bonus_expires_at = v_expires,
        updated_at = NOW()
    WHERE id = v_usage.id
    RETURNING * INTO v_usage;
    
    RETURN v_usage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction: Vérifier les limites
CREATE OR REPLACE FUNCTION check_feature_limits(p_user_id UUID)
RETURNS TABLE (
    scan_used INT,
    scan_limit INT,
    coach_used INT,
    coach_limit INT,
    scan_remaining INT,
    coach_remaining INT
) AS $$
DECLARE
    v_usage usage_tracking;
    v_free_scans INT := 5;
    v_free_coach INT := 10;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    v_usage := get_or_create_usage(p_user_id);
    
    -- Vérifier expiration des bonus
    IF v_usage.bonus_expires_at IS NOT NULL AND v_usage.bonus_expires_at < v_now THEN
        v_usage.scan_bonus := 0;
        v_usage.coach_bonus := 0;
    END IF;
    
    RETURN QUERY
    SELECT 
        v_usage.scan_count,
        v_free_scans + v_usage.scan_bonus,
        v_usage.coach_message_count,
        v_free_coach + v_usage.coach_bonus,
        GREATEST(0, v_free_scans + v_usage.scan_bonus - v_usage.scan_count),
        GREATEST(0, v_free_coach + v_usage.coach_bonus - v_usage.coach_message_count);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- TRIGGER POUR updated_at
-- ═══════════════════════════════════════════════════════════

CREATE TRIGGER update_usage_tracking_updated_at
    BEFORE UPDATE ON usage_tracking
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON TABLE usage_tracking IS 'Suivi de l\'usage des features freemium par utilisateur et par mois';
COMMENT ON COLUMN usage_tracking.month_year IS 'Format YYYY-MM pour regrouper par mois';
COMMENT ON COLUMN usage_tracking.scan_bonus IS 'Bonus de scans obtenus via pubs récompensées';
COMMENT ON COLUMN usage_tracking.bonus_expires_at IS 'Date d\'expiration des bonus (généralement minuit)';
