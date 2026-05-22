-- V5: Pattern results persistence
CREATE TABLE quant.pattern_result (
    id SERIAL PRIMARY KEY,
    symbol TEXT REFERENCES quant.stock(symbol) ON DELETE CASCADE,
    pattern_type TEXT NOT NULL, -- GOLDEN_CROSS, STAGE2_BREAKOUT, etc.
    confidence DECIMAL NOT NULL,
    logic_data JSONB, -- The extra context (SMA values, etc)
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pattern_result_symbol ON quant.pattern_result(symbol);
CREATE INDEX idx_pattern_result_detected ON quant.pattern_result(detected_at);
