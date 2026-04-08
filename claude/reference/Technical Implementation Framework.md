# Technical Implementation Framework: Strategic AI Orchestration and Workflow Standardization

> **Version:** 2.0 — Audit-Driven Revision
> **Last Updated:** 2026-03-15
> **Author:** Configuration Audit by Claude Opus 4.6

---

## 1. The Paradigm Shift: From Manual Coding to AI Orchestration

Modern engineering is moving away from the traditional, labor-intensive practice of line-by-line manual coding and toward a model of high-level AI orchestration. This shift represents a fundamental change in leverage: the developer's role transitions from a "doer" to an "orchestrator," driving productivity gains of 10-15x. In this paradigm, we treat the AI system as a specialized "second brain" that executes high-velocity iterations. By abstracting the syntax layer, architects can focus on system design and validation, transforming the software development lifecycle (SDLC) into a self-optimizing engine.

### The Orchestration Model

Effective orchestration utilizes a Parent-Child agent relationship. The Parent agent maintains the high-level project vision and delegates scoped, technical tasks to specialized sub-agents (Children).

| Feature | Manual Developer Role | AI Orchestrator Role |
|---------|----------------------|---------------------|
| Primary Activity | Writing syntax and debugging line-by-line. | Defining technical specs and trajectory. |
| Testing | Manual unit testing and QA cycles. | Verifying outputs via automated test-driven loops. |
| Context | Managing local file knowledge in memory. | Governing rule tiers and token density. |
| Leverage | Linear output based on hours worked. | Exponential output via parallel agent execution. |

### Core Methodology: Task-Do-Verify

To maximize leverage, teams must adopt the Task-Do-Verify loop. AI is not inherently more precise than a human; its value lies in its superior speed. While a human might reach 100% quality in five hours, an AI can hit an 80% quality bar in seconds. The orchestrator's value is found in the "test-driven" verification loop to bridge the 80% to 100% quality gap through rapid iteration. We reach perfection through the speed of the loop, not the accuracy of the first shot.

This orchestration requires a robust structural foundation within the project environment to prevent architectural drift.

---

## 2. Architectural Foundation: The .claude Directory Hierarchy

A standardized, hidden directory structure serves as the project's "brain." Standardizing the .claude folder ensures consistency across distributed teams and prevents hallucinations regarding project architecture.

### Global vs. Local Rule Tiers

Configuration must be managed through three rigorous layers:

1. **Global Level** (`~/.claude/`): The "Home" configuration. Universal guardrails and organizational defaults.
2. **Project Level** (`./.claude/`): Repository-specific overrides defining unique architecture, tech stacks, and goals.
3. **Enterprise Level**: Managed system-level configurations for high-level compliance and security governance.

### Standard Directory Structure

```
~/.claude/
├── CLAUDE.md                    # Global behavioral instructions (primacy position)
├── settings.json                # Permission modes, hooks, marketplace config
├── audit.log                    # Auto-generated: all agent actions logged here
├── Technical Implementation Framework.md  # This document
├── AGENTS.md                    # Agent registry with model assignments
├── SKILLS.md                    # Skills catalogue with domain tags
│
├── agents/                      # Agent definitions (.agent.md files)
│   ├── plan-mode.agent.md       # Canonical planning agent
│   ├── context-architect.agent.md
│   ├── software-engineer-agent.agent.md
│   ├── debug.agent.md
│   ├── terraform.agent.md
│   └── ...
│
├── skills/                      # Skill definitions (SKILL.md files)
│   ├── {skill-name}/
│   │   ├── SKILL.md             # Frontmatter + checklist
│   │   ├── references/          # Optional: reference docs
│   │   └── resources/           # Optional: playbooks, templates
│   └── ...
│
├── hooks/                       # Hook scripts (future: when extracted from settings.json)
│
├── projects/                    # Project-scoped memory and configuration
│   └── {project-hash}/
│       └── memory/
│           ├── MEMORY.md        # Memory index
│           └── *.md             # Individual memory files
│
└── scheduled-tasks/             # Automated recurring tasks
```

### The CLAUDE.md Specification: Context Dynamics

The `CLAUDE.md` file is the trajectory-setter for every session. Its effectiveness is governed by how LLMs process information within the context window:

- **Primacy Effect**: The agent prioritizes instructions at the very beginning of the file. Critical guardrails and core project definitions must reside here.
- **Recency Effect**: The agent prioritizes the most recent turns in the conversation history.
- **The Middle Gap Warning**: LLMs are statistically less likely to recall information buried in the middle of a large context window. All high-priority constraints must avoid the "middle" and be reinforced in the header or repeated at the point of execution.

---

## 3. Operational Governance: Security, Quality, and Design Protocols

As agents gain autonomy, the platform engineer must balance execution velocity with security guardrails.

### Permission Mode Matrix

| Permission Mode | Oversight Level | Primary Use Case |
|----------------|----------------|-----------------|
| Plan Mode | Read-Only | Strategic research, architectural design, and blueprinting. |
| Ask Before Edits | High | High-risk legacy codebases requiring manual approval. |
| Edit Automatically | Moderate | Balanced workflow for trusted files and rapid iterations. |
| Bypass Permissions | Low | High-velocity execution in sandboxed environments. |

> **Security Warning**: "Bypass Permissions" carries the "Sudo RM" risk. Use only in sandboxed environments.

### Hooks Architecture (Enforcement Layer)

Hooks are the enforcement mechanism that transforms governance documentation into executable policy. Configured in `settings.json`, they intercept agent actions at three lifecycle points:

#### Pre-Execution Hooks (PreToolUse)

| Hook | Purpose | Trigger |
|------|---------|---------|
| Destructive Operation Gate | Blocks `rm -rf`, `git reset --hard`, `terraform apply`, `DROP TABLE`, `force push` | Any Bash command matching destructive patterns |
| Secrets Scanner | Blocks content containing API keys, tokens, passwords, connection strings | Edit/Write operations |
| Scope Validator | Validates change is within the active plan's file list | Edit/Write to files not in `tasks/todo.md` |
| Terraform Plan-Only | Converts `terraform apply` to `terraform plan` | Bash containing `terraform apply` |

#### Post-Execution Hooks (PostToolUse)

| Hook | Purpose | Trigger |
|------|---------|---------|
| Audit Logger | Logs agent name, tool, exit code, timestamp to `~/.claude/audit.log` | Every Edit, Write, and Bash execution |
| Test Runner Gate | Runs relevant test suite after code changes | Edit to `*.ts`, `*.py`, `*.cs` files |
| Lint Check | Runs language-appropriate linter | Edit to source files |

#### Error Hooks

| Hook | Purpose | Trigger |
|------|---------|---------|
| Rollback Trigger | `git stash` uncommitted changes on failure | Agent error/non-zero exit |
| Incident Logger | Appends failure context to `tasks/incidents.md` | Agent error |
| Notification | Desktop notification or webhook alert | Any error hook trigger |

### Technical Security Protocols

- **.gitignore Enforcement**: All sensitive local configuration files (`.claude.local.md`, `settings.local.json`) must be in `.gitignore`.
- **settings.json Audit**: Regularly audit team-wide permissions and tool access limits to ensure least privilege.
- **Audit Log Retention**: `~/.claude/audit.log` is append-only. Review weekly for anomalous patterns.

---

## 4. Agent Governance: Trust Boundaries and Orchestration

### Agent Tier Classification

Every agent operates within a defined trust boundary that determines its autonomy level:

| Tier | Autonomy | Human Gate | Agents |
|------|----------|-----------|--------|
| **Autonomous** | Can execute without confirmation for non-destructive operations | Post-execution review | Software Engineer, Debug Mode, TDD Red/Green, C# Expert, NestJS Backend, Django/DRF Backend, Flutter Mobile |
| **Supervised** | Must present plan/output for approval before execution | Pre-execution approval | Plan Mode, Context Architect, Terraform Agent, Implementation Plan |
| **Advisory** | Read-only analysis and recommendations. Cannot modify files. | N/A (read-only) | Critical Thinking, Devils Advocate, Doublecheck, Mentor Mode |
| **Maximum Effort** | Extended reasoning with high token budget. Use sparingly. | Pre-execution scope agreement | 4.1-Beast, Principal Software Engineer |

### Cross-Agent Handoff Protocol

When one agent produces output for another agent to consume, use this standard contract:

```markdown
## Agent Output Contract
- **Status**: success | partial | failed
- **Agent**: [agent name that produced this output]
- **Files Changed**: [list of modified file paths]
- **Tests**: passed | failed | skipped (with count)
- **Confidence**: high | medium | low
- **Next Action**: [what the downstream agent should do]
- **Blockers**: [any unresolved issues requiring human input]
```

### Agent Routing Rules

| Task Type | Primary Agent | Fallback | Model Tier |
|-----------|--------------|----------|------------|
| Planning / Architecture | Plan Mode | — | Opus |
| Multi-file dependency analysis | Context Architect | — | Opus |
| Implementation (standard) | Software Engineer Agent | — | Sonnet |
| Implementation (complex) | 4.1-Beast | — | Opus |
| Code review | Principal Software Engineer | — | Opus |
| Bug fixing | Debug Mode | — | Sonnet |
| TDD workflow | TDD Red → Green → Refactor | — | Haiku → Haiku → Sonnet |
| Verification | Doublecheck | — | Sonnet |
| Infrastructure | Terraform Agent | — | Sonnet (**plan-only**) |
| NestJS backend | NestJS Backend | — | Sonnet |
| Django/DRF backend | Django/DRF Backend | — | Sonnet |
| Pre-flight validation | Governance Enforcer | — | Haiku |
| End-to-end orchestration | Pipeline Orchestrator | — | Opus |
| Database migrations | Database Migration | — | Sonnet |
| Security scanning | Security Audit | — | Sonnet |
| Cost estimation | Cost Estimator | — | Haiku |
| .NET development | C# Expert / .NET Janitor | — | Sonnet |
| React frontend (Vite + shadcn) | Expert React Frontend | — | Sonnet |
| Next.js frontend (PWA) | Expert Next.js Developer | — | Opus |
| Flutter mobile (iOS/Android) | Flutter Mobile | — | Sonnet |
| Vue/Nuxt | Expert Vue.js / Expert Nuxt | — | Sonnet |
| SRE / reliability tasks | Reliability Engineer | — | Sonnet |

### Escalation Protocol

1. If an agent fails or produces `status: partial` → log to `tasks/incidents.md`
2. If destructive operations are needed → require explicit user confirmation (enforced by hook)
3. If `confidence: low` → invoke Doublecheck agent before proceeding
4. If context window exceeds 50% → compact and start new conversation (hard rule)
5. If infrastructure changes are involved → Terraform Agent outputs plan only; human approves before apply

---

## 5. High-Density Context Management and Technical Debt Mitigation

The primary bottleneck in complex AI-augmented builds is "Context Rot." As a conversation approaches the 200,000-token limit, the quality of logic decreases.

### Token Efficiency: MCP vs. Local Skills

| Approach | Token Cost | Use Case |
|----------|-----------|----------|
| MCP Server connection | 16,000-20,000 tokens | Initial research, prototyping new integrations |
| Local Skill file | ~60 tokens (frontmatter only) | Proven workflows, repeatable processes |

**The Mandate**: Use MCP only for initial research or "sketching." Once a workflow is proven, transition it into a specialized local Skill file.

### Context Budget Rules

| Threshold | Action |
|-----------|--------|
| 40% context used | Warning: consider compacting non-essential history |
| 50% context used | **Hard rule**: Start new conversation. Transfer state via tasks/todo.md and memory files. |
| 60% context used | Emergency: Auto-compact triggered (if hook configured) |

### Compaction and Analysis Protocols

- `/compact`: Triggers summarization-as-compression of conversation history
- `/context`: Audits current environment for token usage

---

## 6. Skills Framework

### Skill Architecture

A "Skill" is a Markdown-based instruction set residing in `.claude/skills/`. It leverages front-matter loading logic: only the `name`, `description`, and `tools` are loaded initially, making them 50-100x more token-efficient than MCP.

### Standard Skill Frontmatter

```yaml
---
name: skill-name
description: One-line description of what this skill does
domain: frontend | backend | devops | data | ai | governance | planning | quality | automation | documentation
governance_tier: autonomous | supervised | advisory
tools: [tool1, tool2]
---
```

### Skill Domain Distribution (Current — 116 skills, ~113 active after consolidation)

| Domain | Count | Coverage Assessment |
|--------|-------|-------------------|
| Frontend (React) | 11 | Strong |
| Frontend (Build Tools — Vite) | 1 | **NEW** — Vite config, optimization, Vitest |
| Frontend (Component Library — shadcn) | 1 | **NEW** — theming, forms, data tables |
| Frontend (Design System — Tailwind) | 1 | **NEW** — tokens, responsive, dark mode |
| Frontend (PWA & Offline) | 1 | **NEW** — service workers, IndexedDB, sync |
| Frontend (Vue) | 0 | **Gap** — Vue/Nuxt in your stack but no skills |
| Mobile (Flutter) | 1 | **NEW** — Drift, Riverpod, Clean Architecture |
| Backend (.NET/C#) | 12 | Strong |
| Backend (Java) | 6 | Moderate (not primary stack) |
| Backend (Python) | 3 | Weak for a primary language |
| Backend (Node.js/NestJS) | 1 | Covered (was critical gap) |
| Backend (Django/DRF) | 1 | Covered |
| Backend (API Design) | 1 | Covered |
| Backend (Resilience) | 1 | **NEW** — circuit breakers, retries, bulkheads, DLQ |
| Backend (Payments) | 1 | Covered |
| DevOps (Git) | 10 | Strong |
| DevOps (K8s) | 3 | Moderate |
| DevOps (Terraform) | 2 | Moderate |
| DevOps (Docker) | 1 | Covered |
| DevOps (GitOps/ArgoCD) | 2 | Covered |
| Observability | 2 | Moderate |
| AI/LLM | 11 | Strong (some redundancy) |
| Prompt Engineering | 2 | Consolidated from 5 |
| N8N | 7 | Strong |
| Planning/Spec | 7 | Strong |
| Data/SQL | 5 | Covered (was weak) |
| Operations (Incident/DR) | 2 | **NEW** — incident response, backup/disaster recovery |
| Security (Secrets/Supply Chain) | 2 | **NEW** — Vault secrets management, supply chain security |
| Delivery (Feature Flags) | 1 | **NEW** — Unleash progressive delivery |
| Quality (Load Testing) | 1 | **NEW** — k6 methodology, capacity planning |
| Governance | 6 | Moderate |

### Recommended Skill Consolidations

| Cluster | Keep | Retire/Merge | Result |
|---------|------|-------------|--------|
| Prompt Engineering (5) | `prompt-engineering` | Merge others into it | 5 → 1 |
| GitHub Workflows (3) | `github-actions-templates` | Merge `github-automation`, `github-workflow-automation` | 3 → 1 |
| LLM Development (4) | `llm-app-patterns` + `llm-ops` | Retire `llm-application-dev-langchain-agent` (not in stack) | 4 → 2 |

### Skills to Add (Priority Order)

| Skill | Domain | Purpose | Priority |
|-------|--------|---------|----------|
| `nestjs-best-practices` | backend | NestJS modules, providers, guards, Prisma integration | ~~P0~~ **DONE** |
| `django-drf-best-practices` | backend | DRF serializers, viewsets, permissions, throttling | ~~P0~~ **DONE** |
| `pre-commit-governance` | governance | Pre-execution validation checklist for all agent work | ~~P0~~ **DONE** |
| `prisma-migrations` | data | Migration generation, seeding, production deploy safety | ~~P1~~ **DONE** |
| `redis-patterns` | backend | Streams pub/sub, caching strategies, session externalization | ~~P1~~ **DONE** |
| `terraform-plan-review` | devops | Plan output analysis, drift detection, cost estimation | ~~P1~~ **DONE** |
| `api-design-review` | backend | REST API review: versioning, pagination, errors, idempotency | ~~P1~~ **DONE** |
| `database-schema-review` | data | PostgreSQL indexing, normalization, migration safety | ~~P1~~ **DONE** |
| `docker-multi-stage` | devops | Multi-stage build optimization, layer caching, scanning | ~~P2~~ **DONE** |
| `stripe-integration` | backend | Stripe Elements, webhook idempotency, PCI-DSS SAQ A | ~~P2~~ **DONE** |
| `microk8s-operations` | devops | MicroK8s addon management, HA setup, troubleshooting | ~~P2~~ **DONE** |
| `argocd-deployment` | devops | Application definitions, sync policies, Argo Rollouts | ~~P2~~ **DONE** |
| `resilience-patterns` | backend | Circuit breakers, retries, bulkheads, graceful degradation | ~~P3~~ **DONE** |
| `load-testing` | quality | k6 load testing, capacity planning, profiling, CI/CD perf gates | ~~P3~~ **DONE** |
| `incident-response` | operations | Severity classification, runbooks, blameless postmortems | ~~P3~~ **DONE** |
| `backup-disaster-recovery` | operations | PostgreSQL WAL, etcd backup, ZFS snapshots, RTO/RPO | ~~P3~~ **DONE** |
| `feature-flags` | delivery | Unleash on MicroK8s, progressive delivery, kill switches | ~~P3~~ **DONE** |
| `secrets-management` | security | Vault on MicroK8s, External Secrets, dynamic credentials | ~~P3~~ **DONE** |
| `supply-chain-security` | security | Trivy SBOM, Renovate, Cosign signing, Kyverno admission | ~~P3~~ **DONE** |

---

## 7. Agent Framework

### Agent Inventory (48 agents post-consolidation)

See `AGENTS.md` for the full registry with model assignments, parameters, and system prompt summaries.

### Agents Removed (This Audit)

| Agent | Reason |
|-------|--------|
| `gpt-5-beast-mode.agent.md` | Non-functional. Tool list references VS Code/Copilot APIs. |
| `planner.agent.md` | Duplicate of `plan.agent.md`. Consolidated to single planning agent. |

### Agents Flagged for Future Consolidation

| Action | Agents | Rationale | Status |
|--------|--------|-----------|--------|
| ~~Merge~~ | ~~Thinking Beast Mode + Ultimate Transparent Thinking~~ | ~~Identical intent~~ | **DONE** — Merged into `beast-mode.agent.md` (2026-03-15) |
| ~~Merge~~ | ~~Prompt Builder + Prompt Engineer~~ | ~~Both do prompt improvement~~ | **DONE** — Prompt Builder deleted (2026-03-15) |
| Differentiate | Mentor Mode + Sensei | Keep both: Mentor for peer review, Sensei for junior onboarding | TODO |

### Agents to Add (Priority Order)

| Agent | Model | Domain | Purpose | Priority |
|-------|-------|--------|---------|----------|
| NestJS Backend Agent | Sonnet | Backend | NestJS + Prisma patterns for Shop MVP | ~~P0~~ **DONE** |
| Django/DRF Backend Agent | Sonnet | Backend | DRF views, serializers for MTPA platform | ~~P0~~ **DONE** |
| Governance Enforcer | Haiku | Governance | Pre-flight validation: scope, plan alignment, destructive op gate | ~~P0~~ **DONE** |
| Pipeline Orchestrator | Opus | Cross-domain | Meta-agent: Plan → Context → Implement → Test → Review → Deploy | ~~P1~~ **DONE** |
| Database Migration Agent | Sonnet | Data | Prisma, Django ORM, EF Core migration safety | ~~P1~~ **DONE** |
| Security Audit Agent | Sonnet | Governance | Trivy-equivalent, SAST, dependency scanning, secrets detection | ~~P1~~ **DONE** |
| Cost Estimator Agent | Haiku | DevOps | AWS/bare-metal cost implications of infra changes | ~~P2~~ **DONE** |
| Reliability Engineer | Sonnet | Operations/SRE | Unified SRE: SLOs, incidents, load tests, capacity, DR | ~~P3~~ **DONE** |

---

## 8. Implementation Roadmap

### Phase 1: Governance & Safety Guardrails (Week 1-2)

**Objective:** Establish enforcement mechanisms before scaling automation.

| Action | Type | Status |
|--------|------|--------|
| Configure destructive-op-gate hook in settings.json | Hook | **DONE** |
| Configure audit-logger hook in settings.json | Hook | **DONE** |
| Add cross-agent handoff protocol to CLAUDE.md | Config | **DONE** |
| Delete non-functional GPT-5 Beast Mode agent | Cleanup | **DONE** |
| Consolidate duplicate planning agents | Cleanup | **DONE** |
| Create Governance Enforcer agent (Haiku) | Agent | **DONE** |
| Add secrets-scan hook (content-level scanning) | Hook | **DONE** |
| Add scope-validator hook (plan alignment check) | Hook | **DONE** |

**Success Criteria:**
- No destructive command executes without explicit confirmation
- Every agent action is logged with timestamp and tool name
- Agent routing is deterministic for common task types

### Phase 2: Consistency Standards (Week 2-3)

**Objective:** Standardize naming, conventions, and output formats.

| Action | Type |
|--------|------|
| Rename all agent files to kebab-case | Config |
| Consolidate remaining duplicate agents (Beast modes, Prompt agents) | Agent | **DONE** |
| Consolidate duplicate skills (Prompt cluster, GitHub cluster) | Skill | **DONE** |
| Add domain tags to all skill frontmatter | Config |
| Create standard skill frontmatter template | Config |
| Enforce standard agent output contract | Config |

**Success Criteria:**
- All agents use kebab-case naming
- Agent count: 46 active (14 Opus / 28 Sonnet / 4 Haiku)
- Skill count: 104 → ~101 after consolidation (3 merged, 1 retired)
- Every skill has a `domain` tag

### Phase 3: Discoverability Infrastructure (Week 3-4)

**Objective:** Make skills and agents findable.

| Action | Type |
|--------|------|
| Generate SKILLS.md index with domain grouping | Config |
| Create skill selection decision tree | Config |
| Create agent selection decision tree | Config |
| Update CLAUDE.md with cross-references to AGENTS.md, SKILLS.md | Config |

**Success Criteria:**
- Any engineer finds the right skill in <30 seconds
- Agent selection is deterministic for common task types

### Phase 4: Execution Velocity (Week 4-6)

**Objective:** Fill coverage gaps and enable end-to-end workflows.

| Action | Type |
|--------|------|
| Create `nestjs-best-practices` skill | Skill | **DONE** |
| Create `django-drf-best-practices` skill | Skill | **DONE** |
| Create `pre-commit-governance` skill | Skill | **DONE** |
| Create `prisma-migrations` skill | Skill | **DONE** |
| Create `database-schema-review` skill | Skill | **DONE** |
| Create NestJS Backend Agent | Agent | **DONE** |
| Create Django/DRF Backend Agent | Agent | **DONE** |
| Create Database Migration Agent | Agent | **DONE** |
| Create Pipeline Orchestrator Agent | Agent | **DONE** |
| Create Security Audit Agent | Agent | **DONE** |
| Create Cost Estimator Agent | Agent | **DONE** |
| Create `docker-multi-stage` skill | Skill | **DONE** |
| Create `stripe-integration` skill | Skill | **DONE** |
| Create `microk8s-operations` skill | Skill | **DONE** |
| Create `argocd-deployment` skill | Skill | **DONE** |
| Create `redis-patterns`, `api-design-review`, `terraform-plan-review` skills | Skill | **DONE** |
| Configure test-runner-gate hook | Hook | **DONE** |
| Configure token-budget-check hook | Hook | **DONE** |

**Success Criteria:**
- Full backend coverage for NestJS and Django
- End-to-end orchestrated workflow: requirement → plan → implement → test → review
- Token budget automatically managed per 50% rule

---

## 9. Audit Log — Changes Made (2026-03-15)

| Change | Type | Detail |
|--------|------|--------|
| Added destructive-op-gate hook | Hook | PreToolUse hook blocking `rm -rf`, `git reset --hard`, `terraform apply`, `DROP TABLE`, `force push` |
| Added audit-logger hook | Hook | PostToolUse hook logging all Edit/Write/Bash actions to `~/.claude/audit.log` |
| Added cross-agent handoff protocol | CLAUDE.md | Standard output contract + routing rules + escalation protocol |
| Deleted `gpt-5-beast-mode.agent.md` | Agent | Non-functional — referenced VS Code/Copilot APIs |
| Deleted `planner.agent.md` | Agent | Duplicate of `plan.agent.md` — consolidated to single planning agent |
| Generated SKILLS.md | Config | Domain-tagged skills catalogue for discoverability |
| Consolidated Beast Mode cluster | Agent | 3 agents (1,115 lines) → 1 agent (130 lines), 88% reduction |
| Consolidated Prompt agents | Agent | Prompt Builder deleted, Prompt Engineer is canonical |
| Created `nestjs-best-practices` skill | Skill | P0 — NestJS modules, Prisma, Redis Streams, SAGA orchestration |
| Created `django-drf-best-practices` skill | Skill | P0 — DRF services, serializers, Celery, PostgreSQL optimization |
| Created `pre-commit-governance` skill | Skill | P0 — 7-section pre-execution validation checklist |
| Created `prisma-migrations` skill | Skill | P1 — Safe migration patterns, seeding, production deploy |
| Created `redis-patterns` skill | Skill | P1 — Cache-aside, Streams, sessions, rate limiting, distributed locks |
| Created `terraform-plan-review` skill | Skill | P1 — Plan analysis, drift detection, cost estimation |
| Created `api-design-review` skill | Skill | P1 — REST API standards: pagination, errors, idempotency |
| Created `database-schema-review` skill | Skill | P1 — PostgreSQL indexing, normalization, constraints |
| Created Governance Enforcer agent | Agent | Haiku-tier pre-flight validation gate |
| Created NestJS Backend agent | Agent | Sonnet-tier for Shop MVP backend |
| Created Django/DRF Backend agent | Agent | Sonnet-tier for MTPA platform backend |
| Created `docker-multi-stage` skill | Skill | P2 — Multi-stage builds, layer caching, Trivy scanning, non-root |
| Created `stripe-integration` skill | Skill | P2 — PCI-DSS SAQ A, webhook idempotency, double-entry ledger |
| Created `microk8s-operations` skill | Skill | P2 — Addon management, HA, storage, troubleshooting, hardening |
| Created `argocd-deployment` skill | Skill | P2 — Application definitions, sync policies, Argo Rollouts, Vault |
| Created Pipeline Orchestrator agent | Agent | Opus-tier meta-agent for end-to-end workflow orchestration |
| Created Database Migration agent | Agent | Sonnet-tier for Prisma/Django/EF Core migration safety |
| Created Security Audit agent | Agent | Sonnet-tier for SAST, secrets, OWASP Top 10, container scanning |
| Created Cost Estimator agent | Agent | Haiku-tier for AWS vs bare-metal cost analysis |
| Added secrets-scan hook | Hook | PreToolUse — blocks API keys, tokens, connection strings, private keys, JWTs |
| Added scope-validator hook | Hook | PreToolUse — warns when Edit/Write targets files not in current plan |
| Added test-runner-gate hook | Hook | PostToolUse — reminds to run tests after code modifications |
| Added token-budget-check hook | Hook | PostToolUse — placeholder for future token API integration |
| Differentiated Mentor vs Sensei | Agent | Added `When to Use` criteria: Mentor = peer review, Sensei = junior onboarding |
| Consolidated GitHub workflow skills | Skill | `github-workflow-automation` merged into `github-actions-templates` (AI PR review, smart test selection, rollback, branch cleanup) |
| Consolidated Prompt Engineering skills | Skill | `prompt-engineer` + `prompt-builder` merged into `prompt-engineering` (frameworks, Copilot template). `boost-prompt` retired |
| Created `vite-react-config` skill | Skill | Vite config for React + TypeScript: build optimization, HMR, plugins, env, proxy, Vitest |
| Created `shadcn-ui-patterns` skill | Skill | shadcn/ui patterns: theming, dark mode, forms (RHF + Zod), data tables, command palette |
| Created `tailwind-design-system` skill | Skill | Tailwind CSS design system: config, tokens, responsive, animations, cn() utility |
| Created `pwa-offline-first` skill | Skill | PWA offline-first: service workers (Workbox), manifest, IndexedDB, background sync |
| Created `flutter-mobile-development` skill | Skill | Flutter mobile: Clean Architecture, Drift (SQLite), Riverpod, dio, go_router, offline sync |
| Created Flutter Mobile agent | Agent | Sonnet-tier for Flutter iOS/Android with Drift cache and offline-first patterns |
| Updated Pipeline Orchestrator | Agent | Added Flutter Mobile, PWA, and shadcn rows to Agent Selection Matrix; added parallel sub-phases for dual-client projects |
| Updated AGENTS.md | Registry | Added Flutter Mobile entry; model distribution: 14 Opus / 29 Sonnet / 4 Haiku = 47 total |
| Updated SKILLS.md | Registry | Added 5 new domain sections; skill count: ~106 active |

### Audit Log — Changes Made (2026-03-22)

| Change | Type | Detail |
|--------|------|--------|
| Created `resilience-patterns` skill | Skill | P3 — Circuit breakers, retries, bulkheads, health probes, DLQ for NestJS/.NET on MicroK8s. 4 resource files |
| Created `load-testing` skill | Skill | P3 — k6 methodology ladder, capacity planning, PostgreSQL/Redis profiling, CI/CD perf gates. 3 resource files |
| Created `incident-response` skill | Skill | P3 — SEV1-4 classification, runbooks, blameless postmortems, ntfy alerts. 3 resource files |
| Created `backup-disaster-recovery` skill | Skill | P3 — PostgreSQL WAL/PITR, etcd backup, ZFS snapshots, RTO/RPO planning. 4 resource files |
| Created `feature-flags` skill | Skill | P3 — Unleash on MicroK8s, progressive delivery, canary metrics, kill switches. 3 resource files |
| Created `secrets-management` skill | Skill | P3 — Vault Helm on MicroK8s, External Secrets Operator, dynamic PostgreSQL creds, PKI. 3 resource files |
| Created `supply-chain-security` skill | Skill | P3 — Trivy SBOM, Renovate, Cosign signing, Kyverno admission, license compliance. 3 resource files |
| Extended `api-design-review` skill | Skill | Added OAuth 2.0 PKCE, JWT rotation, mTLS, OWASP security headers, input validation (Zod/DRF), API key management |
| Extended `observability-engineer` skill | Skill | Added SLO recording rules (PromQL), error budgets, multi-window burn-rate alerts, PLG/Alloy specifics. 2 resource files (prometheus-slo-rules.yaml, grafana-slo-dashboard.json) |
| Extended `argocd-deployment` skill | Skill | Added Kustomize overlay details, ApplicationSet git/matrix generators, config promotion pipeline, drift detection alerts. 1 resource file (argocd-appset-multi-env.yaml) |
| Extended `microk8s-operations` skill | Skill | Added namespace-per-environment pattern, namespace-level RBAC, tiered resource quotas. 1 resource file (namespace-env-rbac.yaml) |
| Created Reliability Engineer agent | Agent | Sonnet-tier unified SRE: SLOs, incidents, load tests, capacity planning, DB profiling, DR verification |
| Updated Technical Implementation Framework | Config | Agent routing (+1), skill domain counts (+7), skill/agent tables marked DONE, audit log, model distribution (Sonnet 29→30, total 47→48) |

---

## 10. Appendix: Model Cost Optimization

### Model Selection Criteria

| Factor | Opus | Sonnet | Haiku |
|--------|------|--------|-------|
| Use when | Deep reasoning, multi-step planning, architectural decisions, complex debugging | Standard coding, code review, configuration, analysis | Repetitive tasks, boilerplate, validation, lightweight checks |
| Token budget | 8,192 max | 4,096 max | 2,048 max |
| Temperature | 0.5-0.7 (reasoning) | 0.3-0.4 (coding) | 0.2 (deterministic) |
| Cost tier | High | Moderate | Low |

### Current Distribution (Post-Consolidation Target)

| Tier | Count | Percentage |
|------|-------|------------|
| Opus | 14 | 29% |
| Sonnet | 30 | 63% |
| Haiku | 4 | 8% |
| **Total** | **48** | 100% |

**Optimization opportunity:** Several Opus agents (e.g., Go MCP Server Expert, ARM Migration) are rarely used. Consider demoting to Sonnet for cost savings if usage is <1x/week.
