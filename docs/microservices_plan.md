# Microservices Design & Implementation Plan

This plan details service-by-service APIs, data models, dependencies, deployment, scaling, observability, and security for the multi-cloud recommendation platform.

## 1. Service Catalog

### 1.1 User Service (AWS EKS + RDS PostgreSQL)
- Purpose: Manage users, profiles, preferences
- APIs:
  - POST /users
  - GET /users/{id}
  - PATCH /users/{id}
- Data Model (Postgres): users(id, email, name, preferences JSONB, created_at)
- Dependencies: RDS, Recommendation Service (read), Auth
- Deployment: Helm chart, 2→50 replicas, HPA on CPU 60% or RPS
- Security: JWT validation, role-based routes
- Observability: Prom metrics (http_requests_total, latency), logs JSON, traces

### 1.2 Product Service (AWS EKS + MongoDB Atlas)
- Purpose: Catalog/search
- APIs: POST /products, GET /products/{id}, GET /products?query=...
- Data Model (Mongo): products(_id, name, category, price, tags[], attributes{}, updated_at)
- Indexes: text(name, tags), category, price range
- Observability/Security same as above

### 1.3 Recommendation Service (Azure AKS + TF Serving + Redis)
- Purpose: Serve personalized recommendations
- API: GET /recommendations?userId=123&topK=20
- Flow: fetch features from Redis → query TF Serving → post-filter by availability → return top-N
- A/B testing: header X-Exp-Variant or gateway route split (e.g., 90/10)
- Latency Target: P95 < 100ms

### 1.4 Event Tracking Service (AWS EKS + Kafka/Redis Streams)
- Purpose: Capture clicks, views, cart, purchases
- APIs: POST /events with event schema
- Topics/Streams: events.click, events.view, events.cart, events.purchase
- Sinks: S3 (canonical), Azure Blob (replica)

### 1.5 Feature Store Service (Azure Redis Cache + S3/Blob)
- Purpose: online features (Redis), offline parquet (S3/Blob)
- APIs: GET /features/{userId}, POST /features/{userId}
- Keys: feature:user:{id}

### 1.6 Cart & Checkout (AWS Lambda + RDS)
- APIs: POST /cart, DELETE /cart/{itemId}, POST /checkout
- DB: RDS orders, order_items
- Integrations: Recommendation (upsell), Notification

### 1.7 Analytics Service (Azure AKS)
- Purpose: Aggregate metrics; expose Prometheus metrics (CTR, conversions)
- Exports: /metrics endpoint; dashboards in Grafana

### 1.8 Notification Service (GCP Cloud Run)
- Triggers: checkout success events
- Channels: Email/SMS via SendGrid/Twilio

### 1.9 Search Service (Elasticsearch)
- APIs: GET /search?q=...&category=...
- Index: products with analyzers; support category facets

### 1.10 API Gateway (Kong/AWS API Gateway)
- Routes: /users, /products, /events, /recommendations, /cart, /checkout, /search
- Policies: JWT/OAuth2, rate limiting, quotas, CORS

### 1.11 A/B Testing Service (Azure Function)
- Assign users to variants, persist assignment, expose decision API

### 1.12 Cost Monitoring Service (AWS)
- Poll AWS Cost Explorer, Azure, GCP; expose /costs; Prom metrics for Grafana

## 2. Data Schemas
- Event (JSON): { userId, sessionId, type, productId?, ts, meta{} }
- Orders: orders(id, user_id, total, status, created_at); order_items(order_id, product_id, qty, price)
- Feature Store: Redis key feature:user:{id} → JSON with recency, frequency, embeddings pointer

## 3. Messaging
- Kafka topics (partitions sized for throughput): events.click, events.view, events.cart, events.purchase
- DLQs for poison messages; consumers write parquet batches hourly to S3/Blob

## 4. Deployment & Scaling
- Containers: Docker with non-root users; distroless where possible
- Helm values per env; HPAs: CPU 60%, memory 70%, custom RPS if using KEDA
- Readiness probes ensure TF Serving model loaded before traffic
- PDBs to maintain availability during rollouts

## 5. Observability
- Prometheus metrics per service + business KPIs
- Grafana dashboards: service overview, recommendation latency, CTR/CVR, event ingestion lag, DB health
- Logs: structured JSON, central EFK; correlation IDs propagated via headers
- Tracing: OpenTelemetry SDK → Tempo/Jaeger (optional)

## 6. Security
- JWT/OAuth2 at gateway; per-service RBAC
- Secrets: Key Vault/Secrets Manager mounted via CSI; rotate regularly
- TLS: Ingress TLS; mTLS optional intra-cluster
- Scanning: Trivy in CI; SAST/dep checks; runtime Falco optional

## 7. MLOps Integration
- Training pipeline:
  - Ingest events → offline features (S3/Blob parquet)
  - Train model → log to MLflow → register model → promote to Staging
  - CI/CD deploys TF Serving with new model tag
- A/B testing: variant assignment, traffic split 90/10 → 50/50 if SLO met
- Rollback: demote failing model; roll back deployment

## 8. API Examples
```
GET /recommendations?userId=123&topK=10
Response: { userId: 123, items: [{productId: "p1", score: 0.92}, ...] }
```
```
POST /events
{ "userId": 123, "type": "click", "productId": "p1", "ts": "2025-09-30T07:00:00Z" }
```

## 9. Testing Strategy
- Unit + integration tests per service; contract tests for gateway
- Load tests (k6/Locust): browse, search, recommend, cart, checkout
- Chaos experiments: pod disruption, node loss, Kafka broker failover

## 10. Backup & DR
- RDS automated backups + PITR; Blob/S3 versioning; cross-region replication for critical buckets/containers
- Recovery: RTO ≤ 1h, RPO ≤ 15m for databases

## 11. Compliance & Audit
- Access logs retained 90 days; audit trails for infra changes via GitOps and cloud trails

## 12. Deliverables Mapping
- Helm charts per service
- Kubernetes base manifests
- Runbooks: SLOs, alerts, on-call playbooks
- Dashboards: Grafana JSON
- Load test scripts and baseline results
