-- ============================================================================
-- MIGRATION 015: Challenges & Gamification Financière
-- Virality engine - Défis, badges, streaks et leaderboards
-- ============================================================================

-- NOTE: L'ordre de création est important !
-- 1. badges (pas de dépendances)
-- 2. challenges (dépend de badges)
-- 3. user_challenges (dépend de challenges)
-- 4. user_badges (dépend de badges)
-- etc.

-- ----------------------------------------------------------------------------
-- TABLE: badges (CRÉÉE EN PREMIER)
-- Badges collectibles
-- ----------------------------------------------------------------------------
CREATE TABLE badges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Identification
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    
    -- Catégorie
    category TEXT NOT NULL CHECK(category IN (
        'saving',        -- Épargne
        'spending',      -- Dépenses
        'streak',        -- Séries
        'social',        -- Social
        'exploration',   -- Exploration de features
        'special'        -- Événements spéciaux
    )),
    
    -- Niveau du badge
    tier TEXT DEFAULT 'bronze' CHECK(tier IN ('bronze', 'silver', 'gold', 'platinum', 'diamond')),
    
    -- Conditions de déblocage
    unlock_type TEXT NOT NULL CHECK(unlock_type IN (
        'challenge_completion',  -- Compléter un défi
        'streak_days',          -- Série de jours
        'amount_saved',         -- Montant épargné
        'transaction_count',    -- Nombre de transactions
        'feature_usage',        -- Utilisation d'une feature
        'social_share',         -- Partage social
        'special_event'         -- Événement spécial
    )),
    unlock_requirement JSONB NOT NULL,
    -- {
    --   "challenge_code": "no_coffee_week",
    --   "streak_days": 30,
    --   "amount": 1000,
    --   "count": 100
    -- }
    
    -- Visuel
    icon TEXT DEFAULT 'emoji_events',
    icon_color TEXT DEFAULT '#E8A86C',
    background_gradient JSONB DEFAULT '["#E8A86C", "#C4714A"]'::jsonb,
    
    -- Animation spéciale
    animation_type TEXT DEFAULT 'none',
    
    -- Ordre d'affichage
    display_order INTEGER DEFAULT 0,
    
    -- Secret (débloqué caché jusqu'à obtention)
    is_secret BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_badges_category ON badges(category);
CREATE INDEX idx_badges_tier ON badges(tier);
CREATE INDEX idx_badges_unlock_type ON badges(unlock_type);

-- ----------------------------------------------------------------------------
-- TABLE: challenges (CRÉÉE APRÈS badges)
-- Défis disponibles pour les utilisateurs
-- ----------------------------------------------------------------------------
CREATE TABLE challenges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Identification
    code TEXT UNIQUE NOT NULL, -- 'no_coffee_week', 'save_100_euros', etc.
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    
    -- Type de défi
    type TEXT NOT NULL CHECK(type IN (
        'spending_limit',      -- Limite de dépense (ex: 0 café)
        'saving_goal',         -- Objectif d'épargne
        'streak',              -- Série de jours
        'category_reduction',  -- Réduction d'une catégorie
        'transaction_count',   -- Nombre de transactions
        'custom'               -- Personnalisé
    )),
    
    -- Paramètres du défi
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    -- {
    --   "target_amount": 100,
    --   "category": "coffee",
    --   "duration_days": 7,
    --   "comparison_period": "last_month"
    -- }
    
    -- Récompenses
    xp_reward INTEGER DEFAULT 100,
    badge_id UUID REFERENCES badges(id), -- Badge attribué à la complétion
    
    -- Difficulté et fréquence
    difficulty INTEGER DEFAULT 1 CHECK(difficulty BETWEEN 1 AND 5),
    frequency TEXT DEFAULT 'monthly' CHECK(frequency IN ('daily', 'weekly', 'monthly', 'one_time')),
    
    -- Visibilité
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    start_date DATE,
    end_date DATE,
    
    -- Médias
    icon TEXT DEFAULT 'emoji_events',
    color TEXT DEFAULT '#E8A86C',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les performances
CREATE INDEX idx_challenges_type ON challenges(type);
CREATE INDEX idx_challenges_active ON challenges(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_challenges_featured ON challenges(is_featured) WHERE is_featured = TRUE;

-- ----------------------------------------------------------------------------
-- TABLE: user_challenges
-- Progression des défis par utilisateur
-- ----------------------------------------------------------------------------
CREATE TABLE user_challenges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE NOT NULL,
    
    -- Statut
    status TEXT DEFAULT 'active' CHECK(status IN ('active', 'completed', 'failed', 'abandoned')),
    
    -- Progression
    progress_current DECIMAL(10,2) DEFAULT 0,
    progress_target DECIMAL(10,2) NOT NULL,
    progress_percentage INTEGER DEFAULT 0,
    
    -- Données de progression détaillées
    progress_data JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "daily_progress": [{"date": "2024-01-01", "value": 0}, ...],
    --   "checkpoints_reached": [50, 75, 100]
    -- }
    
    -- Dates
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    
    -- Récompenses collectées
    xp_earned INTEGER DEFAULT 0,
    badge_earned BOOLEAN DEFAULT FALSE,
    
    UNIQUE(user_id, challenge_id, started_at)
);

CREATE INDEX idx_user_challenges_user ON user_challenges(user_id);
CREATE INDEX idx_user_challenges_status ON user_challenges(status);
CREATE INDEX idx_user_challenges_active ON user_challenges(user_id, status) WHERE status = 'active';

-- ----------------------------------------------------------------------------
-- TABLE: user_badges
-- Badges obtenus par les utilisateurs
-- ----------------------------------------------------------------------------
CREATE TABLE user_badges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    badge_id UUID REFERENCES badges(id) ON DELETE CASCADE NOT NULL,
    
    -- Contexte du déblocage
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    unlocked_context JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "challenge_id": "uuid",
    --   "streak_count": 30,
    --   "amount": 1500
    -- }
    
    -- Affiché sur le profil
    is_showcased BOOLEAN DEFAULT FALSE,
    showcase_order INTEGER,
    
    -- Partagé sur les réseaux
    shared_at TIMESTAMPTZ,
    share_count INTEGER DEFAULT 0,
    
    UNIQUE(user_id, badge_id)
);

CREATE INDEX idx_user_badges_user ON user_badges(user_id);
CREATE INDEX idx_user_badges_showcased ON user_badges(user_id, is_showcased) WHERE is_showcased = TRUE;

-- ----------------------------------------------------------------------------
-- TABLE: user_streaks
-- Séries de jours consécutifs
-- ----------------------------------------------------------------------------
CREATE TABLE user_streaks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Type de streak
    type TEXT NOT NULL CHECK(type IN (
        'daily_check_in',      -- Connexion quotidienne
        'under_budget',        -- Jours sous budget
        'transaction_logged',  -- Transactions enregistrées
        'no_impulse_buy',      -- Pas d'achat impulsif
        'saving_made'          -- Épargne quotidienne
    )),
    
    -- Compteurs
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_days INTEGER DEFAULT 0,
    
    -- Dernière activité
    last_activity_date DATE,
    
    -- Historique (derniers 30 jours)
    recent_history JSONB DEFAULT '[]'::jsonb,
    -- [true, true, false, true, ...] pour les 30 derniers jours
    
    -- Prochaine récompense de streak
    next_milestone INTEGER DEFAULT 7,
    
    UNIQUE(user_id, type)
);

CREATE INDEX idx_user_streaks_user ON user_streaks(user_id);
CREATE INDEX idx_user_streaks_current ON user_streaks(current_streak DESC);

-- ----------------------------------------------------------------------------
-- TABLE: user_xp
-- Système d'expérience utilisateur
-- ----------------------------------------------------------------------------
CREATE TABLE user_xp (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Niveau actuel
    level INTEGER DEFAULT 1,
    total_xp INTEGER DEFAULT 0,
    
    -- XP pour le niveau actuel
    current_level_xp INTEGER DEFAULT 0,
    xp_to_next_level INTEGER DEFAULT 100,
    
    -- Historique récent
    recent_transactions JSONB DEFAULT '[]'::jsonb,
    -- [{"date": "2024-01-01", "amount": 50, "reason": "challenge_completed"}, ...]
    
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_xp_level ON user_xp(level DESC);

-- ----------------------------------------------------------------------------
-- TABLE: xp_transactions
-- Historique détaillé des gains d'XP
-- ----------------------------------------------------------------------------
CREATE TABLE xp_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    amount INTEGER NOT NULL,
    reason TEXT NOT NULL,
    source_type TEXT NOT NULL CHECK(source_type IN (
        'challenge', 'badge', 'streak', 'login', 'transaction', 'referral', 'social_share'
    )),
    source_id UUID, -- ID de la source (challenge, badge, etc.)
    
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_xp_transactions_user ON xp_transactions(user_id);
CREATE INDEX idx_xp_transactions_created ON xp_transactions(created_at DESC);

-- ----------------------------------------------------------------------------
-- TABLE: leaderboards
-- Classements entre amis/utilisateurs
-- ----------------------------------------------------------------------------
CREATE TABLE leaderboards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Type de classement
    type TEXT NOT NULL CHECK(type IN (
        'weekly_saving',       -- Épargne de la semaine
        'monthly_saving',      -- Épargne du mois
        'streak',              -- Plus longue série
        'challenge_completion', -- Défis complétés
        'xp_earned'            -- XP gagnés
    )),
    
    -- Période
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Statut
    is_active BOOLEAN DEFAULT TRUE,
    is_finalized BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_leaderboards_type_period ON leaderboards(type, period_start, period_end);

-- ----------------------------------------------------------------------------
-- TABLE: leaderboard_entries
-- Entrées des utilisateurs dans les classements
-- ----------------------------------------------------------------------------
CREATE TABLE leaderboard_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    leaderboard_id UUID REFERENCES leaderboards(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Position et score
    rank INTEGER NOT NULL,
    score DECIMAL(12,2) NOT NULL,
    
    -- Données détaillées
    details JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "amount_saved": 500,
    --   "streak_days": 15,
    --   "challenges_completed": 3
    -- }
    
    -- Récompenses
    reward_claimed BOOLEAN DEFAULT FALSE,
    reward_type TEXT,
    reward_amount INTEGER,
    
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(leaderboard_id, user_id)
);

CREATE INDEX idx_leaderboard_entries_leaderboard ON leaderboard_entries(leaderboard_id);
CREATE INDEX idx_leaderboard_entries_rank ON leaderboard_entries(leaderboard_id, rank);
CREATE INDEX idx_leaderboard_entries_user ON leaderboard_entries(user_id);

-- ----------------------------------------------------------------------------
-- TABLE: social_shares
-- Partages sur les réseaux sociaux
-- ----------------------------------------------------------------------------
CREATE TABLE social_shares (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Type de contenu partagé
    content_type TEXT NOT NULL CHECK(content_type IN (
        'badge_unlocked',
        'challenge_completed',
        'streak_milestone',
        'saving_goal_reached',
        'leaderboard_rank',
        'weekly_summary'
    )),
    
    -- Référence au contenu
    content_id UUID,
    
    -- Plateforme
    platform TEXT NOT NULL CHECK(platform IN ('instagram', 'facebook', 'twitter', 'whatsapp', 'other')),
    
    -- Métadonnées du partage
    share_data JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "image_url": "...",
    --   "caption": "...",
    --   "story": true
    -- }
    
    -- Engagement
    views INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    
    -- Récompense
    xp_rewarded INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_social_shares_user ON social_shares(user_id);
CREATE INDEX idx_social_shares_platform ON social_shares(platform);

-- ----------------------------------------------------------------------------
-- FONCTIONS ET TRIGGERS
-- ----------------------------------------------------------------------------

-- Mise à jour automatique de updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_challenges_updated_at
    BEFORE UPDATE ON challenges
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_xp_updated_at
    BEFORE UPDATE ON user_xp
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Calcul automatique du pourcentage de progression
CREATE OR REPLACE FUNCTION calculate_challenge_progress()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.progress_target > 0 THEN
        NEW.progress_percentage = LEAST(100, GREATEST(0, 
            (NEW.progress_current / NEW.progress_target * 100)::INTEGER
        ));
    END IF;
    
    -- Marquer comme complété si 100%
    IF NEW.progress_percentage >= 100 AND NEW.status = 'active' THEN
        NEW.status = 'completed';
        NEW.completed_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_calculate_challenge_progress
    BEFORE INSERT OR UPDATE ON user_challenges
    FOR EACH ROW EXECUTE FUNCTION calculate_challenge_progress();

-- Mise à jour des streaks
CREATE OR REPLACE FUNCTION update_streak_on_activity()
RETURNS TRIGGER AS $$
DECLARE
    last_date DATE;
    today DATE := CURRENT_DATE;
BEGIN
    -- Récupérer la dernière date d'activité
    last_date := NEW.last_activity_date;
    
    IF last_date IS NULL OR last_date < today - INTERVAL '1 day' THEN
        -- Streak cassée ou nouvelle
        NEW.current_streak := 1;
    ELSIF last_date = today - INTERVAL '1 day' THEN
        -- Streak continue
        NEW.current_streak := NEW.current_streak + 1;
        
        -- Mettre à jour le record
        IF NEW.current_streak > NEW.longest_streak THEN
            NEW.longest_streak := NEW.current_streak;
        END IF;
    END IF;
    
    -- Mettre à jour la dernière date si c'est aujourd'hui
    IF last_date IS NULL OR last_date < today THEN
        NEW.last_activity_date := today;
        NEW.total_days := NEW.total_days + 1;
    END IF;
    
    -- Mettre à jour l'historique
    NEW.recent_history := jsonb_build_array(
        true,
        (SELECT COALESCE(jsonb_array_elements_text(NEW.recent_history), 'false') 
         LIMIT 29)
    );
    
    -- Calculer le prochain milestone
    NEW.next_milestone := CASE
        WHEN NEW.current_streak < 7 THEN 7
        WHEN NEW.current_streak < 30 THEN 30
        WHEN NEW.current_streak < 100 THEN 100
        WHEN NEW.current_streak < 365 THEN 365
        ELSE NEW.current_streak + 365
    END;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ----------------------------------------------------------------------------
-- POLITIQUES RLS
-- ----------------------------------------------------------------------------

ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_xp ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_shares ENABLE ROW LEVEL SECURITY;

-- Challenges: tout le monde peut voir les actifs
CREATE POLICY challenges_select ON challenges
    FOR SELECT USING (is_active = TRUE);

-- User challenges: utilisateur voit ses propres défis
CREATE POLICY user_challenges_select ON user_challenges
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY user_challenges_insert ON user_challenges
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY user_challenges_update ON user_challenges
    FOR UPDATE USING (user_id = auth.uid());

-- Badges: tout le monde peut voir
CREATE POLICY badges_select ON badges
    FOR SELECT USING (TRUE);

-- User badges: utilisateur voit ses propres badges
CREATE POLICY user_badges_select ON user_badges
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY user_badges_insert ON user_badges
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY user_badges_update ON user_badges
    FOR UPDATE USING (user_id = auth.uid());

-- Streaks: utilisateur voit ses propres streaks
CREATE POLICY user_streaks_select ON user_streaks
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY user_streaks_insert ON user_streaks
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY user_streaks_update ON user_streaks
    FOR UPDATE USING (user_id = auth.uid());

-- XP: utilisateur voit son propre XP
CREATE POLICY user_xp_select ON user_xp
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY user_xp_insert ON user_xp
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY user_xp_update ON user_xp
    FOR UPDATE USING (user_id = auth.uid());

-- XP transactions: utilisateur voit ses propres transactions
CREATE POLICY xp_transactions_select ON xp_transactions
    FOR SELECT USING (user_id = auth.uid());

-- Leaderboards: tout le monde peut voir
CREATE POLICY leaderboards_select ON leaderboards
    FOR SELECT USING (TRUE);

-- Leaderboard entries: tout le monde peut voir
CREATE POLICY leaderboard_entries_select ON leaderboard_entries
    FOR SELECT USING (TRUE);

-- Social shares: utilisateur voit ses propres partages
CREATE POLICY social_shares_select ON social_shares
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY social_shares_insert ON social_shares
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- VUES POUR FACILITER LES REQUÊTES
-- ----------------------------------------------------------------------------

-- Vue des challenges actifs avec progression utilisateur
CREATE VIEW active_challenges_with_progress AS
SELECT 
    c.*,
    uc.id as user_challenge_id,
    uc.status as user_status,
    uc.progress_current,
    uc.progress_target,
    uc.progress_percentage,
    uc.started_at,
    uc.expires_at,
    CASE 
        WHEN uc.id IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END as is_participating
FROM challenges c
LEFT JOIN user_challenges uc ON c.id = uc.challenge_id 
    AND uc.user_id = auth.uid()
    AND uc.status = 'active'
WHERE c.is_active = TRUE
    AND (c.start_date IS NULL OR c.start_date <= CURRENT_DATE)
    AND (c.end_date IS NULL OR c.end_date >= CURRENT_DATE);

-- Vue du classement des amis (simulé avec tous les utilisateurs pour l'instant)
CREATE VIEW friends_leaderboard AS
SELECT 
    ux.user_id,
    p.full_name,
    p.avatar_url,
    ux.level,
    ux.total_xp,
    RANK() OVER (ORDER BY ux.total_xp DESC) as rank
FROM user_xp ux
JOIN profiles p ON ux.user_id = p.id
ORDER BY ux.total_xp DESC
LIMIT 100;

-- ----------------------------------------------------------------------------
-- DONNÉES DE DÉMONSTRATION (Badges de base)
-- ----------------------------------------------------------------------------

INSERT INTO badges (code, name, description, category, tier, unlock_type, unlock_requirement, icon, icon_color, display_order) VALUES
-- Badges Épargne
('first_saving', 'Premier Pas', 'Épargnez votre premier euro', 'saving', 'bronze', 'amount_saved', '{"amount": 1}', 'savings', '#CD7F32', 1),
('saving_100', 'Centurion', 'Épargnez 100€', 'saving', 'bronze', 'amount_saved', '{"amount": 100}', 'savings', '#CD7F32', 2),
('saving_1000', 'Millénaire', 'Épargnez 1 000€', 'saving', 'silver', 'amount_saved', '{"amount": 1000}', 'savings', '#C0C0C0', 3),
('saving_10000', 'Maître de l''épargne', 'Épargnez 10 000€', 'saving', 'gold', 'amount_saved', '{"amount": 10000}', 'savings', '#FFD700', 4),

-- Badges Streak
('streak_7', 'Semaine parfaite', '7 jours consécutifs sous budget', 'streak', 'bronze', 'streak_days', '{"days": 7}', 'local_fire_department', '#CD7F32', 10),
('streak_30', 'Mois discipliné', '30 jours consécutifs sous budget', 'streak', 'silver', 'streak_days', '{"days": 30}', 'local_fire_department', '#C0C0C0', 11),
('streak_100', 'Centurion des streaks', '100 jours consécutifs sous budget', 'streak', 'gold', 'streak_days', '{"days": 100}', 'local_fire_department', '#FFD700', 12),

-- Badges Dépenses
('no_impulse_week', 'Anti-impulsion', '7 jours sans achat impulsif', 'spending', 'bronze', 'streak_days', '{"days": 7, "type": "no_impulse"}', 'shopping_bag', '#CD7F32', 20),
('coffee_master', 'Maître du café', 'Réduisez vos dépenses café de 50%', 'spending', 'silver', 'challenge_completion', '{"challenge_code": "reduce_coffee"}', 'coffee', '#C0C0C0', 21),

-- Badges Social
('social_butterfly', 'Papillon social', 'Partagez votre premier badge', 'social', 'bronze', 'social_share', '{"count": 1}', 'share', '#CD7F32', 30),
('influencer', 'Influenceur', 'Partagez 10 accomplissements', 'social', 'silver', 'social_share', '{"count": 10}', 'share', '#C0C0C0', 31),

-- Badges Exploration
('scanner_pro', 'Scan Master', 'Scannez 10 tickets de caisse', 'exploration', 'bronze', 'feature_usage', '{"feature": "scanner", "count": 10}', 'document_scanner', '#CD7F32', 40),
('coach_user', 'Élève studieux', 'Posez 10 questions au Coach IA', 'exploration', 'bronze', 'feature_usage', '{"feature": "coach", "count": 10}', 'smart_toy', '#CD7F32', 41),
('predictor', 'Voyant', 'Consultez vos prédictions 7 jours de suite', 'exploration', 'silver', 'streak_days', '{"days": 7, "type": "check_predictions"}', 'trending_up', '#C0C0C0', 42),

-- Badges Spéciaux (Secrets)
('vampire_hunter', 'Chasseur de vampires', 'Détectez et résiliez un abonnement caché', 'special', 'gold', 'special_event', '{"event": "vampire_detected"}', 'visibility_off', '#FFD700', 50),
('early_bird', 'Lève-tôt', 'Connectez-vous avant 6h du matin', 'special', 'bronze', 'special_event', '{"event": "early_login"}', 'wb_sunny', '#CD7F32', 51);

-- Challenges de démonstration
INSERT INTO challenges (code, title, description, type, config, xp_reward, difficulty, frequency, icon, color) VALUES
('no_coffee_week', 'Semaine sans café', '0 dépense café pendant 7 jours', 'spending_limit', '{"category": "coffee", "duration_days": 7, "target_amount": 0}', 200, 2, 'weekly', 'coffee', '#8B5A3A'),
('save_100_week', 'Objectif 100€', 'Épargnez 100€ cette semaine', 'saving_goal', '{"target_amount": 100, "duration_days": 7}', 300, 3, 'weekly', 'savings', '#7DC983'),
('under_budget_7', 'Semaine parfaite', 'Restez sous budget 7 jours de suite', 'streak', '{"duration_days": 7}', 250, 2, 'weekly', 'check_circle', '#E8A86C'),
('reduce_food_20', 'Chef économe', 'Réduisez vos dépenses alimentaires de 20%', 'category_reduction', '{"category": "food", "reduction_percentage": 20}', 400, 4, 'monthly', 'restaurant', '#C4714A'),
('log_all_expenses', 'Comptable', 'Enregistrez toutes vos dépenses pendant 30 jours', 'transaction_count', '{"duration_days": 30, "min_transactions_per_day": 1}', 500, 3, 'monthly', 'receipt_long', '#6B8DD6');
