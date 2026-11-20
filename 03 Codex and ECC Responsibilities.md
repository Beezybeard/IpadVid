# 03 — Codex, ECC, Test Harness and CI: Explicit Roles

## Key rule
**Codex is the implementer. ECC is an optional structured workflow/reviewer available within the coding environment. The project test harness provides objective assertions. CI runs real builds and tests. The human project owner approves company policy and deployment.**

ECC is **already installed** on the user's computer. **Do not reinstall, overwrite `~/.codex`, duplicate hooks, or run an ECC global sync without explicit permission.** ECC might currently be installed for Claude Code only, while Codex integration may or may not be enabled. Detect the actual working integration and degrade gracefully.

## Role and activation matrix

| Participant / capability | Responsibility | Trigger | Deliverable / gate |
| --- | --- | --- | --- |
| **Codex primary agent** | Own code, migrations, UX, tests, documentation, PRs and evidence | Every development task | Working, committed increment plus test results |
| **ECC planner / architect** | Threats, component boundaries, state transitions, failure analysis, planned milestones | Project kickoff, before each major phase, and architectural changes | Short design record, interface/acceptance criteria |
| **ECC `tdd-workflow` / TDD guide** | Write failing unit/contract tests before implementation when possible | Each sync/backend behavior, bug fix or regression | Failing test first, then verified passing test |
| **ECC `code-reviewer`** | Independent correctness, maintainability, test gaps and policy review | After feature completion / before merge | Findings with severity, fixes and retest |
| **ECC `security-review` / `security-scan` where available** | Auth, enrollment, upload/download authorization, local data protection, session secrets, supply chain | Early threat model, security-sensitive edits, before production | Security checklist, resolved critical/high findings |
| **ECC `verification-loop` / `eval-harness`** | Structured debug/measure/iterate against ground truth | Any failed test, unexpected output or behavior mismatch | Reproduction, fix, rerun, summarized delta |
| **ECC `e2e-testing`** | Admin portal happy/failure user flows, where available | Admin feature ready for browser testing | Playwright evidence |
| **Project test harness** | Actual scripted tests in pytest, Playwright, XCTest and on-device manual checklist | Every relevant code change | Pass/fail logs and artifacts |
| **GitHub Actions** | Isolated checks, real macOS Xcode compile and iOS simulator tests, release artifacts after signing | PR / merge / release candidate | CI status and signed/unsigned build provenance |
| **Mosyle administrator + Apple Business administrator** | Org onboarding, Apple distribution/license assignment, managed app installation/removal | Deployment only | App installed on authorized supervised iPads |

## ECC command portability and discoverability
ECC has evolved; invocations differ by runtime, version and whether installed as a native Codex plugin, repository skills, or Claude Code configuration. Read installed help/version rather than hardcoding commands. In recent ECC releases, `tdd-workflow`, `verification-loop`, `eval-harness`, `security-review`, and `e2e-testing` are documented skill surfaces; command shims may be deprecated. Review the actual installed names and use whichever are available.

Recommended **read-only** diagnostics in Codex or PowerShell, not a reinstall:

```powershell
codex --version
codex plugin list --json
```

If native ECC plugin is listed and correctly loads skills, invoke relevant ECC skills natively. If ECC was installed solely for another CLI, either (a) use the handoff's role/checklists manually through Codex, or (b) ask the user before enabling ECC's separate Codex integration. Do not layer a native ECC plugin on top of a legacy copied configuration without checking ownership and conflicts. Do not assume ECC skills are universal across Codex/Claude.

## Applied workflow by phase

### Phase 0 — kickoff
1. Codex reads handoff, establishes repo and decision log.
2. ECC planner/architect (if accessible) challenges architecture, edge cases and least privilege.
3. Codex records ADRs and clearly flags dependencies on Apple Developer/Mosyle access.
4. No cloud credentials or production secrets required at this stage.

### Phase 1 — server contracts and catalog
1. Codex defines schemas, API tests and synthetic fixtures.
2. ECC TDD workflow specifies contracts for enroll/publish/catalog/download and rejects unauthorized access.
3. Codex implements, runs pytest locally.
4. ECC reviewer evaluates code; security reviewer checks auth and signing.
5. CI runs on every PR.

### Phase 2 — iPad offline foundations
1. ECC architect reviews SQLite/filesystem state machine and error recovery before implementation.
2. Codex writes pure Swift tests for selection, readiness, low space and version switching.
3. Codex writes SwiftUI/AVKit implementation.
4. macOS CI compiles/tests iPad target. Windows-only syntax checks do NOT count as compile evidence.
5. ECC code reviewer audits crash/rollover behavior.

### Phase 3 — admin dashboard
1. Codex implements validated upload/publish/version management.
2. ECC TDD + e2e-testing guide acceptance tests.
3. Playwright runs browser flows; ECC security reviewer confirms RBAC and upload integrity.

### Phase 4 — integrated resilience
1. Project harness simulates outages, partial downloads, hash mismatch, expired signing, low storage and conflicts.
2. ECC verification loop iterates until expected observed outputs match; never declare success before tests.
3. macOS CI builds; physical iPad testing confirms iPadOS-specific background/offline behavior.

### Phase 5 — release
1. ECC architect/security reviewer performs release readiness audit.
2. GitHub Actions produces audited build evidence; Apple signing/Custom App distribution is performed with authorized organization access.
3. Mosyle admin deploys initially to one pilot iPad, then other six after field acceptance.

## Required engineer response after each change
Codex should report:
1. Files changed / summary of behavior.
2. Which ECC skill/role was used, or `unavailable — used documented checklist`.
3. Commands/tests actually run, pass/fail counts, relevant logs.
4. Whether a real Xcode build was executed, and link to CI run if applicable.
5. Remaining issues and next narrow task.
6. Updated `IMPLEMENTATION STATUS.md` and relevant decision records.

## Explicit anti-patterns
- Do not have ECC planner implement code while Codex also edits same files concurrently.
- Do not run ECC review as a substitute for automated tests or real device behavior.
- Do not use a fake `xcodebuild` shim or claim a Windows host ran an iPad simulator.
- Do not loop edits endlessly without saving a minimal reproducible failing test and bounding the task.
- Do not run every ECC agent on every trivial copy change; roles are invoked where they add value.
- Do not turn on aggressive/high-trust hooks or automatic secret access without inspection and approval.

## Official references (verified November 2026)
- ECC upstream and Codex instructions: https://github.com/affaan-m/ECC
- Codex project guidance: https://learn.chatgpt.com/docs/agent-configuration/agents-md
- ECC source lists planner/architect, reviewer, TDD, security, verification and e2e patterns and cautions against duplicate installation strategies.
