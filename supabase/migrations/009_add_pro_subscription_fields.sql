-- Migration: Ajout des champs d'abonnement Pro
-- Description: Ajoute les champs nécessaires pour gérer les abonnements Aura Pro via RevenueCat

-- ═══════════════════════════════════════════════════════════
-- AJOUT DES COLONNES
-- ═══════════════════════════════════════════════════════════

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS is_pro BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS pro_entitlement_id TEXT,
ADD COLUMN IF NOT EXISTS pro_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS pro_purchase_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS pro_platform TEXT CHECK (pro_platform IN ('ios', 'android', 'stripe'));

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_profiles_is_pro 
ON profiles(is_pro) 
WHERE is_pro = TRUE;

CREATE INDEX IF NOT EXISTS idx_profiles_pro_expires 
ON profiles(pro_expires_at);

-- ═══════════════════════════════════════════════════════════
-- FONCTION: Vérifier si un utilisateur est Pro
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION is_user_pro(user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    is_pro_user BOOLEAN;
BEGIN
    SELECT is_pro INTO is_pro_user
    FROM profiles
    WHERE id = user_uuid;
    
    RETURN COALESCE(is_pro_user, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- FONCTION: Mettre à jour le statut Pro (appelée par Edge Functions)
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_pro_status(
    user_uuid UUID,
    new_is_pro BOOLEAN,
    entitlement_id TEXT DEFAULT NULL,
    expires_at TIMESTAMPTZ DEFAULT NULL,
    platform TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE profiles
    SET 
        is_pro = new_is_pro,
        pro_entitlement_id = COALESCE(entitlement_id, pro_entitlement_id),
        pro_expires_at = COALESCE(expires_at, pro_expires_at),
        pro_platform = COALESCE(platform, pro_platform),
        updated_at = NOW()
    WHERE id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON COLUMN profiles.is_pro IS 'Indique si l\'utilisateur a un abonnement Pro actif';
COMMENT ON COLUMN profiles.pro_entitlement_id IS 'ID de l\'entitlement RevenueCat (ex: aura_pro)';
COMMENT ON COLUMN profiles.pro_expires_at IS 'Date d\'expiration de l\'abonnement Pro';
COMMENT ON COLUMN profiles.pro_purchase_date IS 'Date d\'achat initial de l\'abonnement Pro';
COMMENT ON COLUMN profiles.pro_platform IS 'Plateforme d\'achat: ios, android, ou stripe';
