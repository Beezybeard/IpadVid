# 09 — Copy/Paste Codex Kickoff Prompt

Open the folder from this handoff as the initial repository workspace (or copy these Markdown files into the root of a new private Git repository). Then use the prompt below. **This is a directive to start development**, not a request for a second generic specification.

---

## Prompt for Codex

You are the lead developer of the **All Fab Video Library**, a native iPad SwiftUI/AVKit application with an offline-first selectively downloaded MP4 library, a small FastAPI/PostgreSQL media backend, and a React/TypeScript web administration dashboard. I am developing from **Windows only**. Company devices are seven Mosyle-supervised iPads, ranging from **32 GB to 256 GB**. They have no signed-in Apple Accounts. Content consists of company-owned H.264/AAC MP4s at approximately 1080p, mostly <=5 minutes and at most around 10 minutes. Most employees need only 2–5 downloaded videos at a time. No quality selector, transcoding system or YouTube integration.

**Before coding:** Read `README - Start Here.md`, `AGENTS.md`, and all files `01` through `08` in this handoff. Treat these as the project contract. Do not conflate the native app, backend, the ECC development harness or the actual automated test harness.

**ECC is already installed on my machine.** Inspect whether ECC's workflow/skill integration is available to *this Codex runtime*, using read-only checks first. Do not reinstall ECC, run a global sync, overwrite hooks, or modify global Codex config. Apply ECC planner/architect at the architectural stage; TDD for each core sync and backend behavior; independent code review after features; security review for authentication, media authorization and release; verification-loop on failures. If a skill is unavailable, carry out the equivalent checklist manually and record that fact. `03 Codex and ECC Responsibilities.md` defines exact triggers and ownership.

**Start with Phase 0**, then Phase 1 from `05 Implementation Phases.md`. Make concrete repository files and executable tests. Implement in small vertical slices. For backend/admin work, run tests on Windows. Create GitHub Actions macOS CI to truly compile the iPad Swift project once it exists; never claim Windows can run Xcode. Before production, a separate authorized All Fab administrator must assist with Apple Business/Apple Developer/Mosyle—do not treat lack of that access as a reason not to begin development.

**Most critical functional promise:** after successful per-video download and verification, employee opens the app fully offline and uses the **native Apple player** on a local persistent file. Updating a video must never destroy the last good local copy if downloading, file verification or storage reservation fails. Build a foreground **Sync Before Leaving** readiness flow because iOS background updates are not guaranteed.

**Process for each phase:**
1. State the narrow implementation goal, assumptions and objective acceptance tests.
2. Use ECC review/planning as prescribed, without duplicate installation.
3. Implement tests before functionality where appropriate.
4. Write production-quality code, configuration templates and documentation.
5. Actually run relevant tests and record pass/fail output; provide CI evidence if applicable.
6. Ask ECC reviewer/security reviewer at the designated checkpoints or use manual fallback.
7. Record status and outstanding risks in `IMPLEMENTATION STATUS.md`.
8. Proceed to the next phase only after its completion gate is met; if blocked by real Apple/company access, document and continue another independent phase.

**First answer/action I want from you:** Summarize your read of the contract in at most one page, identify any contradictions, confirm available ECC integration without installation, lay out the Phase 0/1 implementation tasks, and **begin creating the actual repository foundation and first executable tests**. Do not respond with only another generic plan. Do not request a Mac or Mosyle access before starting.

---

## Follow-up prompt for later phases

Continue the All Fab Video Library from `IMPLEMENTATION STATUS.md` and `05 Implementation Phases.md`. Select the next unmet milestone, state expected tests, use the relevant ECC role(s), implement one bounded slice, execute appropriate local/macOS CI checks, update docs and report only verified results. In particular, do not report physical-iPad acceptance unless tested on a real iPad.
