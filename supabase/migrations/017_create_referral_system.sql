-- ============================================================================
-- MIGRATION 017: Système de Parrainage Viral
-- Acquisition à coût nul - "Parraine un ami, 1 mois Pro offert"
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE: referral_codes
-- Codes de parrainage personnalisés
-- ----------------------------------------------------------------------------
CREATE TABLE referral_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Code unique (ex: "AURA-JOHN-2024")
    code TEXT UNIQUE NOT NULL,
    
    -- Propriétaire
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Personnalisation
    custom_slug TEXT, -- ex: "john25" pour aura.finance/ref/john25
    is_custom BOOLEAN DEFAULT FALSE,
    
    -- Stats
    total_clicks INTEGER DEFAULT 0,
    total_signups INTEGER DEFAULT 0,
    total_conversions INTEGER DEFAULT 0, -- Signups qui sont devenus actifs
    
    -- Tracking UTM
    utm_source TEXT DEFAULT 'app',
    utm_medium TEXT DEFAULT 'referral',
    utm_campaign TEXT,
    
    -- Statut
    is_active BOOLEAN DEFAULT TRUE,
    deactivated_at TIMESTAMPTZ,
    deactivation_reason TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_referral_codes_user ON referral_codes(user_id);
CREATE INDEX idx_referral_codes_code ON referral_codes(code);
CREATE INDEX idx_referral_codes_slug ON referral_codes(custom_slug) WHERE custom_slug IS NOT NULL;

-- ----------------------------------------------------------------------------
-- TABLE: referral_relationships
-- Liens entre parrain et filleul
-- ----------------------------------------------------------------------------
CREATE TABLE referral_relationships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Référence
    referrer_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL, -- Parrain
    referred_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL, -- Filleul
    
    -- Code utilisé
    referral_code_id UUID REFERENCES referral_codes(id),
    code_used TEXT NOT NULL,
    
    -- Source du clic
    clicked_at TIMESTAMPTZ, -- Quand le lien a été cliqué
    signed_up_at TIMESTAMPTZ DEFAULT NOW(), -- Quand l'inscription a eu lieu
    converted_at TIMESTAMPTZ, -- Quand l'utilisateur est devenu actif (première transaction)
    
    -- Contexte
    referrer_ip TEXT,
    user_agent TEXT,
    
    -- Statut
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'active', 'expired', 'fraud_suspected')),
    
    -- Récompenses distribuées
    referrer_rewarded BOOLEAN DEFAULT FALSE,
    referred_rewarded BOOLEAN DEFAULT FALSE,
    referrer_reward_details JSONB DEFAULT '{}'::jsonb,
    referred_reward_details JSONB DEFAULT '{}'::jsonb,
    
    UNIQUE(referred_id) -- Un utilisateur ne peut être parrainé qu'une fois
);

CREATE INDEX idx_referral_relationships_referrer ON referral_relationships(referrer_id);
CREATE INDEX idx_referral_relationships_referred ON referral_relationships(referred_id);
CREATE INDEX idx_referral_relationships_status ON referral_relationships(status);
CREATE INDEX idx_referral_relationships_converted ON referral_relationships(converted_at) WHERE converted_at IS NOT NULL;

-- ----------------------------------------------------------------------------
-- TABLE: referral_rewards
-- Historique des récompenses de parrainage
-- ----------------------------------------------------------------------------
CREATE TABLE referral_rewards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    relationship_id UUID REFERENCES referral_relationships(id),
    
    -- Type de récompense
    reward_type TEXT NOT NULL CHECK(reward_type IN (
        'pro_month',      -- 1 mois Pro
        'pro_year',       -- 1 an Pro
        'pro_lifetime',   -- Pro à vie
        'scan_credits',   -- Crédits scan IA
        'coach_credits',  -- Crédits coach IA
        'custom'          -- Récompense personnalisée
    )),
    
    -- Quantité
    quantity INTEGER DEFAULT 1,
    
    -- Description
    description TEXT NOT NULL,
    
    -- Statut
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'granted', 'revoked', 'expired')),
    
    -- Dates
    granted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    revocation_reason TEXT,
    
    -- Métadonnées
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_referral_rewards_user ON referral_rewards(user_id);
CREATE INDEX idx_referral_rewards_status ON referral_rewards(status);
CREATE INDEX idx_referral_rewards_type ON referral_rewards(reward_type);

-- ----------------------------------------------------------------------------
-- TABLE: referral_milestones
-- Jalons de récompenses (5 parrainages = 1 an Pro)
-- ----------------------------------------------------------------------------
CREATE TABLE referral_milestones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Jalon
    milestone_type TEXT NOT NULL CHECK(milestone_type IN (
        'first_referral',    -- 1er parrainage
        'five_referrals',    -- 5 parrainages
        'ten_referrals',     -- 10 parrainages
        'twenty_referrals',  -- 20 parrainages
        'fifty_referrals',   -- 50 parrainages
        'hundred_referrals'  -- 100 parrainages
    )),
    
    -- Nombre de parrainages requis
    referrals_required INTEGER NOT NULL,
    
    -- Récompense
    reward_type TEXT NOT NULL,
    reward_quantity INTEGER DEFAULT 1,
    reward_description TEXT NOT NULL,
    
    -- Statut
    achieved_at TIMESTAMPTZ,
    claimed BOOLEAN DEFAULT FALSE,
    claimed_at TIMESTAMPTZ,
    
    UNIQUE(user_id, milestone_type)
);

CREATE INDEX idx_referral_milestones_user ON referral_milestones(user_id);
CREATE INDEX idx_referral_milestones_achieved ON referral_milestones(achieved_at) WHERE achieved_at IS NOT NULL;

-- ----------------------------------------------------------------------------
-- FONCTION: Générer un code de parrainage
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_referral_code(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_code TEXT;
    v_username TEXT;
    v_exists BOOLEAN;
BEGIN
    -- Récupérer le nom de l'utilisateur
    SELECT COALESCE(full_name, 'USER') INTO v_username
    FROM profiles WHERE id = p_user_id;
    
    -- Nettoyer le nom
    v_username := UPPER(REGEXP_REPLACE(v_username, '[^a-zA-Z]', '', 'g'));
    v_username := LEFT(v_username, 8);
    
    -- Générer un code unique
    LOOP
        v_code := 'AURA-' || v_username || '-' || SUBSTRING(MD5(RANDOM()::TEXT), 1, 4);
        
        SELECT EXISTS(SELECT 1 FROM referral_codes WHERE code = v_code) INTO v_exists;
        EXIT WHEN NOT v_exists;
    END LOOP;
    
    RETURN v_code;
END;
$$;

-- ----------------------------------------------------------------------------
-- FONCTION: Créer automatiquement un code au premier accès
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ensure_referral_code()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_code TEXT;
BEGIN
    -- Vérifier si l'utilisateur a déjà un code
    IF NOT EXISTS (SELECT 1 FROM referral_codes WHERE user_id = NEW.id) THEN
        v_code := generate_referral_code(NEW.id);
        
        INSERT INTO referral_codes (code, user_id)
        VALUES (v_code, NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$;

-- Trigger pour créer automatiquement un code
CREATE TRIGGER trigger_ensure_referral_code
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION ensure_referral_code();

-- ----------------------------------------------------------------------------
-- FONCTION: Traiter une conversion (filleul actif)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION process_referral_conversion(p_referred_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_relationship RECORD;
    v_referrer_count INTEGER;
BEGIN
    -- Trouver la relation
    SELECT * INTO v_relationship
    FROM referral_relationships
    WHERE referred_id = p_referred_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    -- Marquer comme converti
    UPDATE referral_relationships
    SET 
        status = 'active',
        converted_at = NOW()
    WHERE id = v_relationship.id;
    
    -- Mettre à jour les stats du code
    UPDATE referral_codes
    SET total_conversions = total_conversions + 1,
        updated_at = NOW()
    WHERE id = v_relationship.referral_code_id;
    
    -- Créer les récompenses (1 mois Pro pour les deux)
    INSERT INTO referral_rewards (user_id, relationship_id, reward_type, description, status, granted_at, expires_at)
    VALUES 
        (v_relationship.referrer_id, v_relationship.id, 'pro_month', '1 mois Pro offert - Parrainage', 'granted', NOW(), NOW() + INTERVAL '1 month'),
        (v_relationship.referred_id, v_relationship.id, 'pro_month', '1 mois Pro offert - Bienvenue', 'granted', NOW(), NOW() + INTERVAL '1 month');
    
    -- Mettre à jour les flags
    UPDATE referral_relationships
    SET 
        referrer_rewarded = TRUE,
        referred_rewarded = TRUE,
        referrer_reward_details = jsonb_build_object('type', 'pro_month', 'granted_at', NOW()),
        referred_reward_details = jsonb_build_object('type', 'pro_month', 'granted_at', NOW())
    WHERE id = v_relationship.id;
    
    -- Vérifier les jalons pour le parrain
    SELECT COUNT(*) INTO v_referrer_count
    FROM referral_relationships
    WHERE referrer_id = v_relationship.referrer_id AND status = 'active';
    
    -- Mettre à jour les jalons atteints
    UPDATE referral_milestones
    SET achieved_at = NOW()
    WHERE user_id = v_relationship.referrer_id 
      AND referrals_required <= v_referrer_count
      AND achieved_at IS NULL;
      
END;
$$;

-- ----------------------------------------------------------------------------
-- RLS POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_milestones ENABLE ROW LEVEL SECURITY;

-- referral_codes: lecture pour le propriétaire
CREATE POLICY "Users can view own referral codes"
    ON referral_codes FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can update own referral codes"
    ON referral_codes FOR UPDATE
    USING (user_id = auth.uid());

-- Lecture publique pour les codes actifs (pour la page de landing)
CREATE POLICY "Public can view active referral codes"
    ON referral_codes FOR SELECT
    USING (is_active = TRUE);

-- referral_relationships: lecture pour parrain et filleul
CREATE POLICY "Users can view own referral relationships"
    ON referral_relationships FOR SELECT
    USING (referrer_id = auth.uid() OR referred_id = auth.uid());

-- referral_rewards: lecture pour le propriétaire
CREATE POLICY "Users can view own rewards"
    ON referral_rewards FOR SELECT
    USING (user_id = auth.uid());

-- referral_milestones: lecture pour le propriétaire
CREATE POLICY "Users can view own milestones"
    ON referral_milestones FOR SELECT
    USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- SEED: Créer les jalons par défaut pour les utilisateurs existants
-- ----------------------------------------------------------------------------
INSERT INTO referral_milestones (user_id, milestone_type, referrals_required, reward_type, reward_description)
SELECT 
    id,
    'first_referral',
    1,
    'pro_month',
    '1 mois Pro offert pour votre premier parrainage'
FROM profiles
ON CONFLICT (user_id, milestone_type) DO NOTHING;

INSERT INTO referral_milestones (user_id, milestone_type, referrals_required, reward_type, reward_description)
SELECT 
    id,
    'five_referrals',
    5,
    'pro_year',
    '1 an Pro offert pour 5 parrainages actifs'
FROM profiles
ON CONFLICT (user_id, milestone_type) DO NOTHING;

INSERT INTO referral_milestones (user_id, milestone_type, referrals_required, reward_type, reward_description)
SELECT 
    id,
    'ten_referrals',
    10,
    'pro_year',
    '1 an Pro offert supplémentaire pour 10 parrainages'
FROM profiles
ON CONFLICT (user_id, milestone_type) DO NOTHING;

INSERT INTO referral_milestones (user_id, milestone_type, referrals_required, reward_type, reward_description)
SELECT 
    id,
    'twenty_referrals',
    20,
    'pro_lifetime',
    'Aura Pro à vie ! Merci pour votre confiance'
FROM profiles
ON CONFLICT (user_id, milestone_type) DO NOTHING;