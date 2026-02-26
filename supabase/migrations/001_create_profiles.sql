-- Migration: Création de la table profiles
-- Description: Table des profils utilisateurs liée à auth.users

-- ═══════════════════════════════════════════════════════════
-- TABLE: profiles
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    avatar_url TEXT,
    monthly_income DECIMAL(12,2),
    currency TEXT DEFAULT 'EUR',
    onboarding_completed BOOLEAN DEFAULT FALSE,
    financial_goals JSONB DEFAULT '{"emergency_fund": 0, "vacation": 0}'::jsonb,
    notification_prefs JSONB DEFAULT '{
        "push_enabled": true,
        "email_enabled": true,
        "vampire_alerts": true,
        "budget_alerts": true,
        "weekly_summary": true
    }'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_profiles_onboarding 
ON profiles(onboarding_completed) 
WHERE onboarding_completed = FALSE;

-- ═══════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy: Les utilisateurs peuvent modifier leur propre profil
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy: Les utilisateurs peuvent créer leur propre profil
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- ═══════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour créer automatiquement le profil lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON TABLE profiles IS 'Profils utilisateurs d''Aura Finance';
COMMENT ON COLUMN profiles.financial_goals IS 'Objectifs financiers: {emergency_fund, vacation, etc.}';
COMMENT ON COLUMN profiles.notification_prefs IS 'Préférences de notification: {push_enabled, email_enabled, etc.}';
