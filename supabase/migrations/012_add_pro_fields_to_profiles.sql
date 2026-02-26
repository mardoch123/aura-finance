-- Migration: Ajout des champs Pro aux profils
-- Description: Gestion du statut d'abonnement Premium

-- ═══════════════════════════════════════════════════════════
-- AJOUT DES COLONNES
-- ═══════════════════════════════════════════════════════════

-- Statut Pro
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS is_pro BOOLEAN DEFAULT FALSE;

-- Date d'expiration de l'abonnement
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS pro_expires_at TIMESTAMPTZ;

-- Type de plan (weekly, annual, monthly)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS pro_plan TEXT 
CHECK (pro_plan IN ('weekly', 'annual', 'monthly', 'unknown'));

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_profiles_is_pro 
ON profiles(is_pro);

CREATE INDEX IF NOT EXISTS idx_profiles_pro_expires 
ON profiles(pro_expires_at);

-- ═══════════════════════════════════════════════════════════
-- RLS POLICIES - IMPORTANT
-- ═══════════════════════════════════════════════════════════

-- Policy: Lecture du statut Pro par le propriétaire
-- Note: is_pro peut être lu par le client Flutter
CREATE POLICY "Users can view own pro status"
ON profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy: Modification de is_pro INTERDITE au client
-- Seul le service_role (webhook RevenueCat) peut modifier ces champs
-- Cette policy est implicite (pas de UPDATE policy pour is_pro/pro_plan/pro_expires_at)

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ═══════════════════════════════════════════════════════════

-- Supprimer la fonction existante si elle existe (pour éviter l'erreur de changement de nom de paramètre)
DROP FUNCTION IF EXISTS is_user_pro(UUID);

-- Fonction: Vérifier si un utilisateur est Pro (avec gestion de l'expiration)
CREATE OR REPLACE FUNCTION is_user_pro(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_pro BOOLEAN;
    v_expires_at TIMESTAMPTZ;
BEGIN
    SELECT is_pro, pro_expires_at 
    INTO v_is_pro, v_expires_at
    FROM profiles 
    WHERE id = p_user_id;
    
    -- Si pas de profil trouvé
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Si pas Pro
    IF NOT v_is_pro THEN
        RETURN FALSE;
    END IF;
    
    -- Si expiration dépassée
    IF v_expires_at IS NOT NULL AND v_expires_at < NOW() THEN
        -- Auto-désactiver (optionnel, le webhook devrait le faire)
        UPDATE profiles 
        SET is_pro = FALSE, 
            pro_expires_at = NULL,
            updated_at = NOW()
        WHERE id = p_user_id;
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction: Activer le statut Pro (pour le webhook)
CREATE OR REPLACE FUNCTION activate_pro(
    p_user_id UUID,
    p_plan TEXT,
    p_expires_at TIMESTAMPTZ
)
RETURNS VOID AS $$
BEGIN
    UPDATE profiles
    SET is_pro = TRUE,
        pro_plan = p_plan,
        pro_expires_at = p_expires_at,
        updated_at = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction: Désactiver le statut Pro (pour le webhook)
CREATE OR REPLACE FUNCTION deactivate_pro(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE profiles
    SET is_pro = FALSE,
        pro_expires_at = NULL,
        updated_at = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- VUE POUR LES STATS
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW pro_stats AS
SELECT 
    COUNT(*) FILTER (WHERE is_pro = TRUE) as total_pro_users,
    COUNT(*) FILTER (WHERE is_pro = TRUE AND pro_plan = 'annual') as annual_subscribers,
    COUNT(*) FILTER (WHERE is_pro = TRUE AND pro_plan = 'weekly') as weekly_subscribers,
    COUNT(*) FILTER (WHERE is_pro = TRUE AND pro_expires_at > NOW() AND pro_expires_at < NOW() + INTERVAL '7 days') as expiring_soon
FROM profiles;

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON COLUMN profiles.is_pro IS 'Statut Premium actif (mis à jour par webhook RevenueCat uniquement)';
COMMENT ON COLUMN profiles.pro_expires_at IS 'Date d\'expiration de l\'abonnement';
COMMENT ON COLUMN profiles.pro_plan IS 'Type de plan: weekly, annual, monthly';
COMMENT ON FUNCTION is_user_pro IS 'Vérifie si un utilisateur a un abonnement Pro actif';
