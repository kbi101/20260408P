-- V1__init_quant_registry.sql
-- Initial migration to establish the 'quant' schema and the infrastructure registry

-- Create Schema
CREATE SCHEMA IF NOT EXISTS quant;

-- Ensure UUID extension for registry IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Infrastructure Registry Table
CREATE TABLE IF NOT EXISTS quant.infra_registry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL,         -- database, cache, compute, worker
    provider TEXT NOT NULL,     -- postgres, redis, questdb, etc
    config JSONB NOT NULL,      -- Secret connection strings/hosts
    metadata JSONB NOT NULL,    -- System paths/versions
    status TEXT NOT NULL DEFAULT 'unknown',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Infrastructure Health Logs (Extensible)
CREATE TABLE IF NOT EXISTS quant.infra_health_logs (
    id SERIAL PRIMARY KEY,
    registry_id UUID REFERENCES quant.infra_registry(id) ON DELETE CASCADE,
    level TEXT NOT NULL,        -- INFO, WARN, ERROR
    message TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexing for performance
CREATE INDEX IF NOT EXISTS idx_registry_type ON quant.infra_registry(type);
CREATE INDEX IF NOT EXISTS idx_registry_provider ON quant.infra_registry(provider);

-- Seed with initial Main Postgres record
INSERT INTO quant.infra_registry (name, type, provider, config, metadata, status)
VALUES (
    'Main PostgreSQL Cluster',
    'database',
    'postgres',
    '{"host": "192.168.1.100", "database": "crystal_db", "user": "postgres", "schema": "quant"}',
    '{"installation": "/var/lib/postgresql/data", "logs": "/var/log/postgresql/postgresql.log", "version": "PostgreSQL 16.1"}',
    'online'
) ON CONFLICT (name) DO NOTHING;
