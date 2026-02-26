-- Migration: Création de la table ai_insights
-- Description: Table des insights et alertes générés par l'IA

-- ═══════════════════════════════════════════════════════════
-- TABLE: ai_insights
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ai_insights (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT CHECK(type IN ('prediction', 'alert', 'tip', 'vampire', 'achievement')) NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    priority INTEGER DEFAULT 5 CHECK(priority >= 1 AND priority <= 10),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    action_taken BOOLEAN DEFAULT FALSE,
    action_type TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_ai_insights_user_read 
ON ai_insights(user_id, is_read, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_insights_type 
ON ai_insights(user_id, type);

CREATE INDEX IF NOT EXISTS idx_ai_insights_priority 
ON ai_insights(user_id, priority) WHERE priority <= 3;

CREATE INDEX IF NOT EXISTS idx_ai_insights_unread 
ON ai_insights(user_id, created_at DESC) WHERE is_read = FALSE;

CREATE INDEX IF NOT EXISTS idx_ai_insights_expires 
ON ai_insights(expires_at) WHERE expires_at IS NOT NULL;

-- ═══════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════

ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres insights
CREATE POLICY "Users can view own insights"
ON ai_insights FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent marquer leurs insights comme lus
CREATE POLICY "Users can update own insights"
ON ai_insights FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent supprimer leurs propres insights
CREATE POLICY "Users can delete own insights"
ON ai_insights FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Note: L'insertion est généralement faite par les Edge Functions ou triggers
CREATE POLICY "Service can create insights"
ON ai_insights FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════

-- Trigger pour marquer la date de lecture
CREATE OR REPLACE FUNCTION mark_insight_as_read()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
        NEW.read_at := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_insight_read_at
    BEFORE UPDATE ON ai_insights
    FOR EACH ROW
    EXECUTE FUNCTION mark_insight_as_read();

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS
-- ═══════════════════════════════════════════════════════════

-- Fonction pour obtenir le nombre d'insights non lus
CREATE OR REPLACE FUNCTION get_unread_insights_count(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    count INTEGER;
BEGIN
    SELECT COUNT(*)::INTEGER
    INTO count
    FROM ai_insights
    WHERE user_id = user_uuid AND is_read = FALSE;
    
    RETURN count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour marquer tous les insights comme lus
CREATE OR REPLACE FUNCTION mark_all_insights_as_read(user_uuid UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE ai_insights
    SET is_read = TRUE, read_at = NOW()
    WHERE user_id = user_uuid AND is_read = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les insights prioritaires
CREATE OR REPLACE FUNCTION get_priority_insights(
    user_uuid UUID,
    min_priority INTEGER DEFAULT 3
)
RETURNS TABLE (
    id UUID,
    type TEXT,
    title TEXT,
    body TEXT,
    priority INTEGER,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.type,
        i.title,
        i.body,
        i.priority,
        i.created_at
    FROM ai_insights i
    WHERE i.user_id = user_uuid
        AND i.is_read = FALSE
        AND i.priority <= min_priority
        AND (i.expires_at IS NULL OR i.expires_at > NOW())
    ORDER BY i.priority ASC, i.created_at DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- VUES
-- ═══════════════════════════════════════════════════════════

-- Vue des insights par type
CREATE OR REPLACE VIEW insights_summary AS
SELECT 
    user_id,
    type,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE is_read = FALSE) as unread_count,
    MAX(created_at) as last_insight_at
FROM ai_insights
WHERE expires_at IS NULL OR expires_at > NOW()
GROUP BY user_id, type;

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON TABLE ai_insights IS 'Insights et alertes générés par l IA';
COMMENT ON COLUMN ai_insights.type IS 'Type: prediction, alert, tip, vampire, achievement';
COMMENT ON COLUMN ai_insights.priority IS 'Priorité de 1 (critique) à 10 (informatif)';
COMMENT ON COLUMN ai_insights.data IS 'Données structurées selon le type d insight';
