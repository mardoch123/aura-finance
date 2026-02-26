-- Migration: Politiques RLS pour le scanner et rate limiting
-- Date: 2026-02-26

-- ═══════════════════════════════════════════════════════════
-- POLITIQUES RLS POUR LE STORAGE (RECEIPTS)
-- ═══════════════════════════════════════════════════════════

-- Activer RLS sur le bucket receipts (si ce n'est pas déjà fait)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'receipts',
  'receipts',
  true,
  10485760, -- 10 MB
  ARRAY['image/jpeg', 'image/png', 'image/heic', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/heic', 'application/pdf'];

-- Politique: Les utilisateurs peuvent uniquement voir leurs propres reçus
CREATE POLICY "Users can view own receipts" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Politique: Les utilisateurs peuvent uniquement uploader dans leur dossier
CREATE POLICY "Users can upload own receipts" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'receipts' 
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND (storage.extension(name)) IN ('jpg', 'jpeg', 'png', 'heic', 'pdf')
  );

-- Politique: Les utilisateurs peuvent supprimer leurs propres reçus
CREATE POLICY "Users can delete own receipts" ON storage.objects
  FOR DELETE
  USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ═══════════════════════════════════════════════════════════
-- FONCTION DE RATE LIMITING POUR LES SCANS
-- ═══════════════════════════════════════════════════════════

-- Table pour suivre l'utilisation des scans
CREATE TABLE IF NOT EXISTS scan_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  scan_date DATE NOT NULL DEFAULT CURRENT_DATE,
  scan_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, scan_date)
);

-- Index pour les recherches rapides
CREATE INDEX IF NOT EXISTS idx_scan_usage_user_date ON scan_usage(user_id, scan_date);

-- RLS sur scan_usage
ALTER TABLE scan_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own scan usage" ON scan_usage
  FOR SELECT
  USING (user_id = auth.uid());

-- Fonction pour incrémenter le compteur de scans
CREATE OR REPLACE FUNCTION increment_scan_count()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO scan_usage (user_id, scan_date, scan_count)
  VALUES (NEW.user_id, CURRENT_DATE, 1)
  ON CONFLICT (user_id, scan_date)
  DO UPDATE SET 
    scan_count = scan_usage.scan_count + 1,
    updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour incrémenter automatiquement le compteur
DROP TRIGGER IF EXISTS tr_increment_scan_count ON transactions;
CREATE TRIGGER tr_increment_scan_count
  AFTER INSERT ON transactions
  FOR EACH ROW
  WHEN (NEW.source = 'scan')
  EXECUTE FUNCTION increment_scan_count();

-- Fonction pour vérifier la limite de scans
CREATE OR REPLACE FUNCTION check_scan_limit(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_count INTEGER;
  v_limit INTEGER := 50; -- Limite quotidienne
BEGIN
  SELECT scan_count INTO v_count
  FROM scan_usage
  WHERE user_id = p_user_id
    AND scan_date = CURRENT_DATE;
  
  RETURN COALESCE(v_count, 0) < v_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- FONCTION DE NETTOYAGE DES IMAGES ANCIENNES
-- ═══════════════════════════════════════════════════════════

-- Fonction pour supprimer les images de plus de 30 jours
CREATE OR REPLACE FUNCTION cleanup_old_receipt_images()
RETURNS void AS $$
DECLARE
  v_cutoff_date TIMESTAMPTZ;
BEGIN
  v_cutoff_date := NOW() - INTERVAL '30 days';
  
  -- Supprimer les références aux images anciennes dans les transactions
  UPDATE transactions
  SET scan_image_url = NULL,
      metadata = metadata || '{"image_deleted": true, "deleted_at": "' || NOW() || '"}'::jsonb
  WHERE source = 'scan'
    AND scan_image_url IS NOT NULL
    AND created_at < v_cutoff_date;
    
  -- Note: Les fichiers dans storage doivent être supprimés via un job externe
  -- ou une Edge Function car PostgreSQL n'a pas accès direct au filesystem
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cron job pour le nettoyage quotidien (nécessite l'extension pg_cron)
-- SELECT cron.schedule('cleanup-receipts', '0 3 * * *', 'SELECT cleanup_old_receipt_images()');

-- ═══════════════════════════════════════════════════════════
-- INDEX ADDITIONNELS POUR LES PERFORMANCES
-- ═══════════════════════════════════════════════════════════

-- Index sur la source pour faciliter les requêtes de statistiques
CREATE INDEX IF NOT EXISTS idx_transactions_source ON transactions(source) WHERE source = 'scan';

-- Index sur la date de création pour le nettoyage
CREATE INDEX IF NOT EXISTS idx_transactions_created_at_source ON transactions(created_at) 
  WHERE source = 'scan' AND scan_image_url IS NOT NULL;

-- ═══════════════════════════════════════════════════════════
-- MISE À JOUR DE LA TABLE TRANSACTIONS
-- ═══════════════════════════════════════════════════════════

-- Ajouter des contraintes sur les catégories valides
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS valid_category;
ALTER TABLE transactions ADD CONSTRAINT valid_category
  CHECK (category IN (
    'food', 'transport', 'housing', 'health', 'entertainment',
    'shopping', 'subscription', 'restaurant', 'travel', 'utilities',
    'education', 'income', 'other'
  ));

-- Ajouter une contrainte sur la source
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS valid_source;
ALTER TABLE transactions ADD CONSTRAINT valid_source
  CHECK (source IN ('manual', 'scan', 'voice', 'import'));
