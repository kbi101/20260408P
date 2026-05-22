-- V13__seed_aapl_journal_sample.sql
-- Seeds a complete AAPL end-to-end Trading Journal sample for the Cognitive Cockpit demo.
-- This provides an out-of-the-box walkthrough record covering:
--   Plan → Position (CLOSED) → Custom Metadata → Psychology Tags → Recap Note

DO $$
DECLARE
    v_sim_account_id  UUID := '00000000-0000-0000-0000-000000000001';
    v_plan_id         UUID := '00000000-0000-0000-0000-000000000100';
    v_position_id     UUID := '00000000-0000-0000-0000-000000000200';
    v_note_id         UUID := '00000000-0000-0000-0000-000000000300';
BEGIN

-- ── 1. Pre-Trade Plan ─────────────────────────────────────────────────────────
INSERT INTO quant.journal_plans (
    plan_id,
    symbol,
    timeframe,
    strategy_name,
    planned_entry,
    planned_stop,
    planned_target,
    planned_risk,
    target_r_multiple,
    checklist_responses,
    locked,
    created_at,
    updated_at
) VALUES (
    v_plan_id,
    'AAPL',
    'DAY_TRADE',
    '5-min Opening Range Breakout',
    150.00,
    148.00,
    156.00,
    100.00,
    3.00,                      -- (156 - 150) / (150 - 148) = 3×R
    '{
        "Wait for first 5-min candle to close": true,
        "Mark high and low of the first 5-min range": true,
        "Enter only on breakout with volume > 1.5x average": true,
        "Check market trend is aligned with breakout": true,
        "Stop loss set at the opposite side of the 5-min range": true
    }'::jsonb,
    TRUE,
    '2026-05-22 14:30:00+00',
    '2026-05-22 14:31:00+00'
) ON CONFLICT (plan_id) DO NOTHING;


-- ── 2. Journal Position (CLOSED) ──────────────────────────────────────────────
INSERT INTO quant.journal_positions (
    position_id,
    plan_id,
    account_id,
    symbol,
    status,
    avg_entry_price,
    avg_exit_price,
    total_shares,
    realized_pnl,
    actual_r_multiple,
    rule_adherence_score,
    psychology_tags,
    entry_time,
    exit_time,
    created_at,
    updated_at
) VALUES (
    v_position_id,
    v_plan_id,
    v_sim_account_id,
    'AAPL',
    'CLOSED',
    150.50,                    -- slight entry drift (within 1.5% of 150.00)
    155.20,                    -- exit below target but profitable
    66,                        -- ~100 / (150 - 148) ≈ 50 shares; rounded to 66 for demo
    314.60,                    -- (155.20 - 150.50) × 66 ≈ $310 rounded
    2.35,                      -- (155.20 - 150.50) / (150.50 - 148.00)
    90,                        -- minor drift penalty (-10), all checklist rules met
    '["Discipline", "Patience"]'::jsonb,
    '2026-05-22 14:32:00+00',
    '2026-05-22 19:55:00+00',
    '2026-05-22 14:30:00+00',
    '2026-05-22 19:55:00+00'
) ON CONFLICT (position_id) DO NOTHING;


-- ── 3. Custom Metadata (Freestyle Layer) ─────────────────────────────────────
INSERT INTO quant.journal_custom_metadata (position_id, key, value) VALUES
    (v_position_id, 'focus_level',       '4'),
    (v_position_id, 'coffee_intake',     '2 cups'),
    (v_position_id, 'sleep_quality',     '4'),
    (v_position_id, 'market_sentiment',  'bullish'),
    (v_position_id, 'catalyst_type',     'Technical Breakout')
ON CONFLICT (position_id, key) DO NOTHING;


-- ── 4. Recap Notebook Note ────────────────────────────────────────────────────
INSERT INTO quant.journal_notes (
    note_id,
    position_id,
    title,
    content_markdown,
    attachment_paths,
    created_at,
    updated_at
) VALUES (
    v_note_id,
    v_position_id,
    'AAPL – 5-min ORB Recap (2026-05-22)',
    E'## Trade Recap: AAPL Opening Range Breakout\n\n'
    '**Symbol:** AAPL  \n'
    '**Strategy:** 5-min Opening Range Breakout  \n'
    '**Timeframe:** Day Trade  \n\n'
    '### Execution Summary\n'
    '- Planned entry: **$150.00** | Actual entry: **$150.50** (drift: +0.33% ✅ within 1.5%)\n'
    '- Planned stop: **$148.00** | Stop held, not triggered ✅\n'
    '- Planned target: **$156.00** | Exited early at **$155.20** (target proximity, EOD risk reduction)\n'
    '- Position size: **66 shares** | Realized P&L: **+$314.60**\n'
    '- Actual R-Multiple: **2.35×** vs planned 3.00×\n\n'
    '### Rule Adherence\n'
    'Score: **90 / 100** — Minor deduction for entry drift (+$0.50 above plan entry). '
    'All checklist items confirmed before entry. Stop loss held intact.\n\n'
    '### Psychology\n'
    'Tags: 🚀 **Discipline**, 🧘 **Patience**  \n'
    'Felt calm and focused throughout. Waited patiently for the confirmed 5-min breakout candle. '
    'Resisted the urge to chase the initial spike and entered on the first clean pullback retest.\n\n'
    '### Conditions\n'
    '- Focus level: **4/5**\n'
    '- Sleep quality: **4/5**\n'
    '- Coffee intake: **2 cups**\n'
    '- Market sentiment: **Bullish** (SPY up 0.8% pre-market)\n'
    '- Catalyst: **Technical Breakout** (AAPL above 50-day MA, strong pre-market volume)\n\n'
    '### Lessons Learned\n'
    '1. Entry was slightly above plan due to spread at open — acceptable but monitor slippage.\n'
    '2. Exiting before the $156 target was the right call given late-session volume fade.\n'
    '3. This setup confirms the 5-min ORB edge is valid in a trending tape.',
    '[]'::jsonb,
    '2026-05-22 20:05:00+00',
    '2026-05-22 20:05:00+00'
) ON CONFLICT (note_id) DO NOTHING;

END $$;
