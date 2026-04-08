# Anti-Patterns & Banned Tools

## Never Suggest These Tools
WordPress, Joomla, Drupal, SharePoint, Laravel/PHP/Ruby, jQuery, Docker Swarm (K8s only), Memcached (Redis), Datadog (Prometheus+Grafana), NFS for K8s (block storage only), AWS EKS for MVPs (MicroK8s bare metal first), SQLite for production.

## Architecture — Never Do
Monoliths for scale (DDD microservices), 2PC (SAGA only), sync inter-service HTTP (async/event-driven), sticky sessions (stateless + Redis), tight service coupling (own-DB mandate), DB full-text search (Elasticsearch/Meilisearch), magic numbers (config/env vars), greenfield rewrites (refactor first), feature bloat (MVP + Must/Should/Could), over-engineering without cost justification.

## Security — Non-Negotiable
Plaintext secrets (Vault/Secrets Manager only), Base64-as-security (not encryption), direct cardholder data (Stripe tokenization), public-by-default (default-deny, LAN-first), unauthenticated endpoints (RBAC/IAM required), root-running services (non-root + sudo), AI bots on local hardware (VPS + VPN).

## Process — Never Do
Skip tests (CI gates), manual deploys (GitOps), undocumented infra (IaC first), build before validate (research first), features without acceptance criteria, unlimited scope (phased delivery).

## Communication — Never Do
Generic advice (be concrete), incomplete code examples (runnable + next steps), "ignore security for speed", vendor lock-in without flagging, single solution as gospel (show alternatives), missing operational details (monitoring/scaling/DR), sunny-day-only (include failure modes).
