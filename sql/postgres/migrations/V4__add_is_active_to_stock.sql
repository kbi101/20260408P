-- Add is_active flag to stock registry
-- This allows toggling ingestion for specific symbols without deleting them

ALTER TABLE quant.stock ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Update existing stocks to be active by default
UPDATE quant.stock SET is_active = TRUE WHERE is_active IS NULL;
