-- Migration: V3__migrate_stock_and_cleanup_temporal
-- 1. Create quant.stock table based on crystal.stock
-- 2. Migrate data from crystal.stock to quant.stock
-- 3. Cleanup accidental Temporal tables in quant schema

-- 1. Create quant.stock
CREATE TABLE IF NOT EXISTS quant.stock (
    symbol character varying(10) PRIMARY KEY,
    shares_outstanding bigint,
    start_date date,
    end_date date,
    memo text,
    market_cap bigint,
    stock_group jsonb
);

-- 2. Migrate data
INSERT INTO quant.stock (symbol, shares_outstanding, start_date, end_date, memo, market_cap, stock_group)
SELECT symbol, shares_outstanding, start_date, end_date, memo, market_cap, stock_group
FROM crystal.stock
ON CONFLICT (symbol) DO NOTHING;

-- 3. Cleanup Temporal tables in quant schema
-- These tables were accidentally created in 'quant' but belong in 'temporal'
DROP TABLE IF EXISTS quant.namespaces CASCADE;
DROP TABLE IF EXISTS quant.namespace_metadata CASCADE;
DROP TABLE IF EXISTS quant.shards CASCADE;
DROP TABLE IF EXISTS quant.executions CASCADE;
DROP TABLE IF EXISTS quant.current_executions CASCADE;
DROP TABLE IF EXISTS quant.buffered_events CASCADE;
DROP TABLE IF EXISTS quant.tasks CASCADE;
DROP TABLE IF EXISTS quant.task_queues CASCADE;
DROP TABLE IF EXISTS quant.replication_tasks CASCADE;
DROP TABLE IF EXISTS quant.replication_tasks_dlq CASCADE;
DROP TABLE IF EXISTS quant.timer_tasks CASCADE;
DROP TABLE IF EXISTS quant.activity_info_maps CASCADE;
DROP TABLE IF EXISTS quant.timer_info_maps CASCADE;
DROP TABLE IF EXISTS quant.child_execution_info_maps CASCADE;
DROP TABLE IF EXISTS quant.request_cancel_info_maps CASCADE;
DROP TABLE IF EXISTS quant.signal_info_maps CASCADE;
DROP TABLE IF EXISTS quant.signals_requested_sets CASCADE;
DROP TABLE IF EXISTS quant.history_node CASCADE;
DROP TABLE IF EXISTS quant.history_tree CASCADE;
DROP TABLE IF EXISTS quant.queue CASCADE;
DROP TABLE IF EXISTS quant.queue_metadata CASCADE;
DROP TABLE IF EXISTS quant.cluster_metadata CASCADE;
DROP TABLE IF EXISTS quant.cluster_membership CASCADE;
DROP TABLE IF EXISTS quant.queues CASCADE;
DROP TABLE IF EXISTS quant.queue_messages CASCADE;
DROP TABLE IF EXISTS quant.cluster_metadata_info CASCADE;
DROP TABLE IF EXISTS quant.nexus_incoming_services CASCADE;
DROP TABLE IF EXISTS quant.history_immediate_tasks CASCADE;
DROP TABLE IF EXISTS quant.history_scheduled_tasks CASCADE;
DROP TABLE IF EXISTS quant.task_queue_user_data CASCADE;
DROP TABLE IF EXISTS quant.build_id_to_task_queue CASCADE;
DROP TABLE IF EXISTS quant.nexus_incoming_services_partition_status CASCADE;
DROP TABLE IF EXISTS quant.visibility_tasks CASCADE;
DROP TABLE IF EXISTS quant.transfer_tasks CASCADE;
DROP TABLE IF EXISTS quant.schema_version CASCADE;
DROP TABLE IF EXISTS quant.schema_update_history CASCADE;
