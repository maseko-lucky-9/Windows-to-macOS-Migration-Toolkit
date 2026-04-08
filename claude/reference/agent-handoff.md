# Agent Handoff Protocol

## Output Contract
Every agent handoff includes: `Status` (success/partial/failed), `Agent`, `Files Changed`, `Tests` (passed/failed/skipped + count), `Confidence` (high/medium/low), `Next Action`, `Blockers`

## Routing
Planning → Plan Mode (Opus) | Plan Review → `/review-plan` skill | Multi-file analysis → Context Architect (Opus) | Pre-flight → Governance Enforcer (Haiku) | Implementation → domain agent per matrix (Sonnet default, Opus for complex) | Task Review → Doublecheck (Sonnet) | TDD → Red (Haiku) → Green (Haiku) → Refactor (Haiku) | Final Review → Principal SE (Opus) | Bugs → Debug Mode (Sonnet) | Infra → Terraform (Sonnet, plan-only, human approval before apply)

## Pipeline Artifact Persistence
All phase outputs written to `pipeline/` subdirectory: `intake-validation.md`, `plan.md`, `plan-review.md`, `context-map.md`, `preflight-report.md`, `tasks/T00N-*.md`, `integration-report.md`, `final-review.md`, `deploy-plan.md`, `build-summary.md`

## Escalation
Agent failure × 2 → escalate to user | Plan review REFINE × 2 → escalate with findings | Destructive ops → user confirmation | Low confidence → Doublecheck first | >40% context → recommend split | >50% context → STOP, write build-summary, new conversation

## Rollback
Task fails after max retries → list completed task changes → ask user: keep or revert → revert only with confirmation
