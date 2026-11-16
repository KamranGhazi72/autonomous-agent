

CREATE EXTENSION IF NOT EXISTS vector;

-- RAG Knowledge Base using 16-bit half-precision vectors (50% less RAM, supports HNSW up to 4000 dims)
CREATE TABLE IF NOT EXISTS technical_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    text TEXT NOT NULL,
    metadata JSONB,
    embedding halfvec(3072)
);

CREATE INDEX IF NOT EXISTS technical_documents_embedding_hnsw_idx
ON technical_documents
USING hnsw (embedding halfvec_cosine_ops);

-- Automated Sales Lead Qualification Table
CREATE TABLE IF NOT EXISTS sales_leads (
    id SERIAL PRIMARY KEY,
    chat_id VARCHAR(100) NOT NULL,
    raw_message TEXT,
    budget VARCHAR(100),
    timeline VARCHAR(100),
    project_scope TEXT,
    lead_score INT,
    priority VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);