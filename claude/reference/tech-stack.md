# Tech Stack & Architecture Defaults

## Languages & Frameworks

| Role | Primary | Secondary | Avoid |
|---|---|---|---|
| **Backend** | C# / .NET Core (.NET 8), Python (Django, DRF, FastAPI, Streamlit) | Node.js / NestJS | PHP, Ruby, Laravel |
| **Frontend** | React / Next.js, Vue / Nuxt.js (SSR for SEO) | TypeScript, Vanilla JS | jQuery, outdated SPA patterns |
| **Data** | Python (Pandas, NumPy), SQL | — | — |
| **DevOps scripting** | Terraform/HCL, Bash, Python | Go (acknowledged, not yet adopted) | PowerShell |
| **Databases** | PostgreSQL (primary), Redis (cache + event streaming) | MySQL, MongoDB, MSSQL, Elasticsearch | SQLite for production data |
| **ORM** | Prisma (Node.js), Django ORM | Entity Framework (.NET) | Raw string SQL in app code |
| **Payments** | Stripe Elements (PCI-DSS SAQ A via tokenization) | — | Direct cardholder data handling |
| **Trading** | MetaTrader 5 (MQL5 Expert Advisors) | — | — |

## Architecture Patterns

- **Microservices with DDD** — bounded contexts, service autonomy, each service owns its database
- **API Gateway** — centralized SSL termination, rate limiting, JWT validation
- **Event-driven / async** — Redis Streams as lightweight broker (Kafka when scale demands it)
- **SAGA pattern** — orchestration-based for distributed transactions (never 2PC)
- **CQRS** — where read/write patterns diverge significantly
- **Clean Architecture** — separation of concerns, dependency inversion, SOLID
- **Stateless services** — session state externalized to Redis for horizontal scaling
- **Idempotent operations** — idempotency keys for payment webhooks, retry-safe services
