-- Migration: Création de la table analytics_events
-- Description: Table pour tracker les événements de monétisation et d'usage

-- ═══════════════════════════════════════════════════════════
-- TABLE: analytics_events
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_name TEXT NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    platform TEXT,
    
    -- Données JSON pour les paramètres spécifiques à l'événement
    params JSONB DEFAULT '{}'::jsonb,
    
    -- Champs dénormalisés pour faciliter les requêtes courantes
    placement TEXT,           -- Pour interstitial_shown
    reward_type TEXT,         -- Pour rewarded_ad_shown
    plan_id TEXT,             -- Pour subscription_*
    feature TEXT,             -- Pour limit_reached, feature_used
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

-- Index pour les requêtes par utilisateur et date
CREATE INDEX IF NOT EXISTS idx_analytics_user_timestamp 
ON analytics_events(user_id, timestamp DESC);

-- Index pour les requêtes par type d'événement
CREATE INDEX IF NOT EXISTS idx_analytics_event_name 
ON analytics_events(event_name, timestamp DESC);

-- Index pour les requêtes par plan (subscriptions)
CREATE INDEX IF NOT EXISTS idx_analytics_plan 
ON analytics_events(plan_id) 
WHERE event_name LIKE 'subscription_%';

-- Index pour les requêtes JSON (GIN)
CREATE INDEX IF NOT EXISTS idx_analytics_params 
ON analytics_events USING GIN(params);

-- ═══════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Les utilisateurs ne peuvent pas voir les événements (lecture admin uniquement)
-- Les events sont insérés par le client mais pas lisibles

-- Policy: Insertion autorisée pour les utilisateurs authentifiés
CREATE POLICY "Users can insert analytics events"
ON analytics_events FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════
-- VUES MATÉRIALISÉES (pour les dashboards)
-- ═══════════════════════════════════════════════════════════

-- Vue: Résumé des conversions par jour
CREATE OR REPLACE VIEW analytics_daily_summary AS
SELECT 
    DATE(timestamp) as date,
    event_name,
    COUNT(*) as count,
    COUNT(DISTINCT user_id) as unique_users
FROM analytics_events
WHERE timestamp >= NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp), event_name
ORDER BY date DESC, count DESC;

-- Vue: Taux de conversion paywall → achat
CREATE OR REPLACE VIEW analytics_paywall_conversion AS
WITH paywall_views AS (
    SELECT 
        user_id,
        timestamp as viewed_at
    FROM analytics_events
    WHERE event_name = 'paywall_shown'
),
purchases AS (
    SELECT 
        user_id,
        timestamp as purchased_at,
        params->>'plan_id' as plan_id
    FROM analytics_events
    WHERE event_name = 'subscription_completed'
)
SELECT 
    DATE(p.viewed_at) as date,
    COUNT(DISTINCT p.user_id) as paywall_views,
    COUNT(DISTINCT pur.user_id) as conversions,
    ROUND(
        COUNT(DISTINCT pur.user_id)::numeric / 
        NULLIF(COUNT(DISTINCT p.user_id), 0)::numeric * 100, 
        2
    ) as conversion_rate
FROM paywall_views p
LEFT JOIN purchases pur ON p.user_id = pur.user_id 
    AND pur.purchased_at > p.viewed_at
    AND pur.purchased_at < p.viewed_at + INTERVAL '1 hour'
WHERE p.viewed_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(p.viewed_at)
ORDER BY date DESC;

-- Vue: Revenus estimés par jour
CREATE OR REPLACE VIEW analytics_daily_revenue AS
SELECT 
    DATE(timestamp) as date,
    params->>'plan_id' as plan_id,
    COUNT(*) as purchases,
    CASE 
        WHEN params->>'plan_id' LIKE '%annual%' THEN 29.99 * COUNT(*)
        WHEN params->>'plan_id' LIKE '%weekly%' THEN 4.99 * COUNT(*)
        ELSE 0
    END as estimated_revenue
FROM analytics_events
WHERE event_name = 'subscription_completed'
    AND timestamp >= NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp), params->>'plan_id'
ORDER BY date DESC;

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS
-- ═══════════════════════════════════════════════════════════

-- Fonction: Obtenir le taux de conversion pour une période
CREATE OR REPLACE FUNCTION get_conversion_rate(
    start_date DATE,
    end_date DATE
)
RETURNS NUMERIC AS $$
DECLARE
    paywall_count INTEGER;
    purchase_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT user_id) INTO paywall_count
    FROM analytics_events
    WHERE event_name = 'paywall_shown'
        AND DATE(timestamp) BETWEEN start_date AND end_date;
    
    SELECT COUNT(DISTINCT user_id) INTO purchase_count
    FROM analytics_events
    WHERE event_name = 'subscription_completed'
        AND DATE(timestamp) BETWEEN start_date AND end_date;
    
    RETURN ROUND(
        purchase_count::numeric / NULLIF(paywall_count, 0)::numeric * 100,
        2
    );
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON TABLE analytics_events IS 'Événements analytics pour tracking monétisation et usage';
COMMENT ON COLUMN analytics_events.event_name IS 'Nom de l\'événement (ex: paywall_shown, subscription_completed)';
COMMENT ON COLUMN analytics_events.params IS 'Paramètres additionnels en JSON';
COMMENT ON COLUMN analytics_events.placement IS 'Positionnement pour les pubs (ex: after_scan, app_open)';
COMMENT ON COLUMN analytics_events.reward_type IS 'Type de récompense pour les pubs récompensées';
COMMENT ON COLUMN analytics_events.plan_id IS 'ID du plan pour les événements d\'abonnement';
COMMENT ON COLUMN analytics_events.feature IS 'Nom de la feature pour limit_reached/feature_used';
