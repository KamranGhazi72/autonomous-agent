# Automate Customer Service Hybrid AI Agent (n8n + PostgreSQL pgvector + Ollama + Whisper)

An enterprise-grade, self-hosted conversational AI system built with **n8n**, **PostgreSQL (`pgvector`)**, **Google Gemini**, and local fallback models (**Ollama** & **OpenAI Whisper**). Designed for high availability, low memory footprint, and decoupled knowledge ingestion.

## Key Architectural Highlights

* **Hybrid Cloud + Local Fallback (Fault Tolerance):** Uses Google Gemini as the primary reasoning and transcription engine, with automatic failover to containerized **Ollama (`llama3.2:1b`)** and **Local Whisper (`tiny`)** during API rate limits or network outages.
* **Memory-Optimized Vector Search (`halfvec` + HNSW):** Leverages `pgvector`'s 16-bit `halfvec(3072)` data type with HNSW indexing for `gemini-embedding-001`, cutting vector RAM/storage consumption by **50%** while bypassing the 2,000-dimension limit of standard 32-bit `vector` HNSW indexes.
* **Multimodal Input Processing:** Seamlessly handles both text and voice notes in Telegram via an asynchronous audio transcription pipeline.
* **Intent-Driven Multi-Agent Routing:** Classifies incoming user queries into distinct operational streams:
  * **Technical Support Stream (RAG):** Retrieves context from `technical_documents` via cosine similarity.
  * **Sales Qualification Stream:** Extracts budget, timeline, and scope into structured JSON, scores leads (`Hot`/`Warm`/`Cold`), and persists them in `sales_leads`.
* **Decoupled Knowledge Ingestion:** A standalone n8n Form workflow (`rag-knowledge-ingestion.json`) chunks, embeds, and indexes PDF/Markdown/TXT documentation independently from real-time chat traffic.

## Architecture Flow

```text
[Telegram User (Text / Voice)]
       │
       ▼
[Normalization & Gemini ASR] ──(On Error)──► [Local Whisper Container]
       │
       ▼
[Intent Classifier] ──(On Error)──► [Local Ollama llama3.2:1b (JSON Mode)]
       │
       ├──► [Support Stream] ──► [AI Agent + Gemini] ──► [pgvector halfvec(3072) HNSW]
       │                              └──(Fallback)──► [Ollama llama3.2:1b]
       │
       └──► [Sales Stream]   ──► [Lead Extractor & Scorer] ──► [PostgreSQL sales_leads]
```

## Repository Structure

```text
autonomous-agent/
├── docker-compose.yml
├── .gitignore
├── init-scripts/
│   └── 01-init-pgvector.sql
├── workflows/
│   ├── CustomerServiceAutomatation.json
│   └── RAG Knowledge Ingestion.json
└── README.md
```

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/KamranGhazi72/autonomous-agent
   cd autonomous-agent
   ```

2. **Configure environment secrets:**
   Update the placeholder values (`change_me_in_production` and `WEBHOOK_URL`) in `docker-compose.yml` with your actual database passwords and public webhook URL.

3. **Start the containerized stack:**
   ```bash
   docker compose up -d
   docker exec -it agent_ollama ollama pull llama3.2:1b
   ```
   *(Note: PostgreSQL automatically executes `init-scripts/01-init-pgvector.sql` on first startup to enable `pgvector` and create the `technical_documents` and `sales_leads` tables).*

4. **Import Workflows:**
   * Open n8n at `http://localhost:5678` and log in using your Basic Auth credentials.
   * Create credentials for **Telegram**, **Google Gemini**, **PostgreSQL** (`host: postgres`, `db: agent_db`), and **Ollama** (`baseUrl: http://agent_ollama:11434`).
   * Import both JSON workflows from the `/workflows` directory and activate the main Telegram workflow.

## Tech Stack

* **Orchestration:** n8n (Self-Hosted)
* **Vector & Relational Database:** PostgreSQL 16 + `pgvector` (`halfvec` HNSW indexing)
* **Primary LLMs & Embeddings:** Google Gemini (`gemini-2.5-flash` / `gemini-embedding-001`)
* **Local Fallback LLMs & ASR:** Ollama (`llama3.2:1b`) & OpenAI Whisper (`tiny`)
* **Infrastructure:** Docker & Docker Compose
