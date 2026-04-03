# Ticket Workflow System — Bootstrap Document

> **Purpose:** This document is the single source of truth for building a standalone, reusable AI-driven ticket workflow system. It captures the full design — what already exists (proven in production), what needs to be built, and the decisions already made. Start here.

---

## 1. What This Project Is

A **file-based, AI-native project management workflow** that runs entirely inside a git repository. No external tools, no databases, no SaaS — just markdown files, shell scripts, and Claude Code configuration.

The system enforces a disciplined single-ticket-at-a-time development process through:
- Slash commands that chain together in a pipeline
- Artifacts produced by one command consumed by the next
- Automated validation via git hooks and Claude Code hooks
- A configurable ticket ID prefix (e.g., `PROJ-XXX`) for reuse across any project

### Core Philosophy

- **One active ticket at a time.** Focus over multitasking.
- **No code changes without a ticket.** Even one-line fixes. The discipline is the point.
- **Files are the state.** The filesystem is the database. Git is the audit trail.
- **Each command is autonomous.** You can run any command independently.
- **Artifacts are the contract.** Commands communicate through markdown files, not implicit state.

---

## 2. Proven Patterns & Reference Designs

Sections 2.1–2.6 describe the core data model and conventions that this system implements. Sections 2.7–2.8 document reference designs from a prior project (proven across 73 tickets) that may be implemented in future phases.

### 2.1 Ticket Format

Every ticket is a markdown file with YAML frontmatter. Canonical template:

```markdown
---
id: PROJ-XXX
title: "<concise title>"
status: backlog | planned | ongoing | completed | rejected
priority: P0 | P1 | P2
type: feature | bugfix | refactor | docs | research | infrastructure
created: YYYY-MM-DD HH:MM:SS
updated: YYYY-MM-DD HH:MM:SS
dependencies: []
assignee: human | ai | unassigned
estimated_complexity: small | medium | large
---

# PROJ-XXX: <title>

## Objective
<!-- One paragraph: what does this ticket accomplish? -->

## Context
<!-- Why is this needed? -->

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Approach
<!-- How should this be implemented? Key files, architecture decisions. -->

## Dependencies
<!-- List ticket IDs that must be completed before this one. -->

## Files Modified
<!-- Filled in during/after implementation. Track every file created or changed. -->

## Decisions
<!-- Design decisions made during this ticket. Reference D-XXX from decisions log. -->

## Notes
<!-- Open questions, risks, links to external resources. -->

## Log
<!-- Append-only log of significant events. -->
- YYYY-MM-DD HH:MM:SS: Ticket created.
```

### 2.2 Directory Structure

```
tickets/
├── TEMPLATE.md        # Canonical ticket template — copy for new tickets
├── backlog/           # Rough ideas, not yet refined
├── planned/           # Refined, ready to activate
│   └── roadmap.md     # Authoritative execution order
├── ongoing/           # The one active ticket (max 1) — stored as subdirectory
│   └── PROJ-XXX/      # Contains ticket.md + plan artifacts
├── completed/         # Successfully finished tickets
└── rejected/          # Cancelled or invalid tickets
```

**Key rule:** Tickets move between directories via `git mv`, never delete+recreate.

### 2.3 Ticket Lifecycle (6 phases)

```
backlog → planned → ongoing → completed
                             → rejected
```

**Create** — Save to `tickets/backlog/PROJ-XXX.md`. Rough ideas, may have incomplete criteria.

**Plan** — Refine all fields, move to `tickets/planned/PROJ-XXX.md`, add to `roadmap.md`. Use `git mv`.

**Activate** — Verify `ongoing/` is empty. Verify all dependencies in `completed/`. Create `tickets/ongoing/PROJ-XXX/` directory, move ticket file inside. Remove row from `roadmap.md`. Use `git mv`.

**Work** — All code changes scoped to the ticket. Track files in "Files Modified". Append to "Log".

**Complete** — Verify all `- [ ]` are `- [x]`. Move entire `tickets/ongoing/PROJ-XXX/` directory to `tickets/completed/PROJ-XXX/`. Single commit.

**Reject** — Document reason in Log. Move to `tickets/rejected/`.

### 2.4 ID Assignment

To assign a new ticket ID:
1. Scan all files across all `tickets/` subdirectories
2. Find the highest `PROJ-XXX` number
3. Increment by 1, zero-pad to 3 digits

### 2.5 Roadmap Format

`tickets/planned/roadmap.md` is a markdown table:

```markdown
# Roadmap

| Position | Ticket | Title | Size | Priority | Dependencies | Rationale |
|----------|--------|-------|------|----------|--------------|-----------|
| 1 | PROJ-005 | Add user auth | medium | P0 | — | Foundation for all features |
| 2 | PROJ-008 | API endpoints | medium | P0 | PROJ-005 | Depends on auth |
| 3 | PROJ-012 | Dashboard UI | large | P1 | PROJ-008 | Needs API |
```

When a ticket is activated, its row is removed from the roadmap.

### 2.6 Commit Convention

Every commit message starts with the ticket ID:
```
PROJ-XXX: Short description of the change
```
One ticket may span multiple commits.

### 2.7 Reference: Validation Patterns (from prior project)

> These validation patterns were proven in a prior project. They are documented here as reference designs for potential future implementation (see Phase 5), not as components that currently exist in this repository.

**Makefile `verify-ticket` target:**
- Checks for duplicate tickets across directories
- Enforces max 1 ticket in `ongoing/`
- Warns about unchecked acceptance criteria in completed tickets
- Hard fail (exit 1) on violations

**Claude Code Stop hook (`verify-ticket-completion.sh`):**
- Detects orphaned ticket files (old path not staged for deletion after move)
- Flags `project_state.md` modified but not staged
- Checks status-directory consistency (e.g., file says `status: planned` but lives in `backlog/`)
- Advisory only — outputs JSON warnings, never blocks

**Pre-commit hooks:**
- Code linting and formatting (ruff or project-specific)
- Trailing whitespace, YAML/TOML validation

### 2.8 Reference: Ticket Analyzer Agent (from prior project)

> This agent design was proven in a prior project. It is documented here as a reference for future implementation (see Phase 5).

A Claude Code sub-agent that evaluates ticket complexity across 7 dimensions:
- Scope (files/functions to change)
- Acceptance criteria count
- Cross-cutting concerns (multiple layers?)
- Dependencies (foundational work needed?)
- Risk (unknowns, research needed?)
- Estimated lines of code
- Logical independence (can parts be separated?)

**Single-ticket threshold:** ≤3 criteria, ≤3 files, single concern, small-to-tight-medium.
**Split threshold:** >3 criteria across concerns, >5 files, mixed infrastructure/feature, implicit sub-tasks.

Also verifies implementation readiness:
- Architecture alignment (correct layers, no dependency violations)
- TDD readiness (domain tests identified before code)
- Documentation completeness

---

## 3. Target Design: The Command Pipeline

### 3.1 Commands Overview

```
/schedule         Backlog → Planned/roadmap (single ticket)
/schedule-batch   Backlog → Planned/roadmap (multiple tickets at once)
      │
      ▼
/analyze          Evaluate the FIRST ticket on the roadmap
      │
      ├── too large ──→  /split   Decompose, put sub-tickets back in flow
      │
      ▼
/plan             Generate implementation-plan.md + test-plan.md
      │                    ↑
      │            [HUMAN APPROVAL GATE]
      ▼
/implement        Execute the plan (worktree, intermediate commits)
      │
      ▼
/verify           Challenge implementation against test-plan
      │
      ├── pass ──→  /commit   Merge worktree, final commit
      │
      └── fail ──→  iterate on /implement or back to /plan
```

### 3.2 Command Specifications

#### `/schedule`

**Purpose:** Move a ticket from `backlog/` to `planned/` and insert it into the roadmap.

**Input:** Ticket ID (e.g., `PROJ-042`) or description for auto-selection.
**Output:** Updated `tickets/planned/roadmap.md`, ticket file moved to `planned/`.
**Behavior:**
1. Read the target ticket from `backlog/`
2. Validate all frontmatter fields are complete, acceptance criteria are concrete
3. If not refined enough, refine it (fill gaps, sharpen criteria)
4. `git mv` to `planned/`
5. Insert into `roadmap.md` at the correct position (respecting dependencies and priority)
6. Update frontmatter: `status: planned`, `updated: <now>`
7. Add log entry

#### `/schedule-batch`

**Purpose:** Schedule multiple tickets at once — useful when starting a new feature set.

**Input:** List of ticket IDs, or a description like "schedule all P0 tickets".
**Output:** Updated roadmap with all tickets inserted in dependency-respecting order.
**Behavior:**
1. For each ticket: validate, refine if needed, `git mv` to `planned/`
2. Topologically sort by dependencies
3. Insert all into `roadmap.md` in the correct order
4. Single commit for the batch

**Note:** `/schedule-batch` is a convenience wrapper around `/schedule`. For most workflows, calling `/schedule` repeatedly achieves the same result. This command adds value when scheduling many related tickets with inter-dependencies, as it handles topological sorting automatically. Lower priority than `/schedule` itself — see Phase 5.

#### `/analyze`

**Purpose:** Evaluate the first ticket on the roadmap for implementation readiness.

**Input:** None (always picks the first ticket from `roadmap.md`).
**Output:** Complexity assessment with verdict (ready / needs split).
**Behavior:**
1. Read `roadmap.md`, identify first ticket
2. Read the ticket file
3. Run the 7-dimension complexity analysis (see section 2.8)
4. Verify implementation readiness (architecture, TDD, documentation)
5. Render verdict:
   - **Ready:** Summary, effort estimate, key files, suggested approach
   - **Too large:** Flag for `/split`
6. If ready, ask: "Shall I activate and plan this ticket?"

#### `/split`

**Purpose:** Decompose a ticket that's too large into smaller sub-tickets.

**Input:** Ticket ID (typically the one just analyzed).
**Output:** Original ticket → `rejected/`. New sub-tickets → `backlog/` (or `planned/` if refined enough).
**Behavior:**
1. Present 2-4 splitting strategies (by layer, by feature, incremental delivery)
2. Each proposal lists sub-tickets with scope and estimated complexity
3. Interactive refinement with the user
4. Once approved: create sub-tickets with sequential IDs, set dependencies between them
5. Mark original as `rejected` with log entry listing new sub-ticket IDs
6. Optionally run `/schedule-batch` on the new sub-tickets

#### `/plan`

**Purpose:** Generate the implementation plan and test plan for the active ticket. This is the human approval gate.

**Input:** Ticket ID (the one being activated, or already in `ongoing/`).
**Output:** Two files inside `tickets/ongoing/PROJ-XXX/`:
- `implementation-plan.md`
- `test-plan.md`

**Behavior:**
1. Activate the ticket: create `tickets/ongoing/PROJ-XXX/` directory, move ticket file inside
2. Read the ticket's acceptance criteria, technical approach, and context
3. Read relevant source code, architecture docs, existing tests
4. Generate `implementation-plan.md`:
   ```markdown
   # Implementation Plan — PROJ-XXX

   ## Overview
   Brief summary of what will be built.

   ## Steps
   ### Step 1: <title>
   - **Files:** list of files to create/modify
   - **What:** description of changes
   - **Tests first:** TDD test(s) to write before implementation
   - **Done when:** observable outcome

   ### Step 2: <title>
   ...

   ## Risk Notes
   Anything that might go wrong or need adjustment.
   ```
5. Generate `test-plan.md`:
   ```markdown
   # Test Plan — PROJ-XXX

   ## Strategy
   Which testing approach (unit, integration, both).

   ## Test Cases
   ### TC-1: <description>
   - **Type:** unit | integration
   - **Target:** function/module being tested
   - **Input:** test data
   - **Expected:** expected outcome
   - **Covers criteria:** which acceptance criteria this validates

   ### TC-2: <description>
   ...

   ## Coverage Map
   | Acceptance Criterion | Test Cases |
   |---------------------|------------|
   | Criterion 1         | TC-1, TC-3 |
   | Criterion 2         | TC-2       |
   ```
6. Present both plans to the user for approval
7. **STOP and wait for human approval.** This is the gate.

#### `/implement`

**Purpose:** Execute the approved implementation plan autonomously.

**Input:** The `implementation-plan.md` in the active ticket's directory.
**Output:** Working code, committed incrementally on a worktree/branch.
**Behavior:**
1. Create a git worktree (or branch) for the work
2. Read `implementation-plan.md`
3. For each step:
   a. Write TDD tests first (per the step's "Tests first" field)
   b. Implement the code
   c. Run tests to verify
   d. Intermediate commit: `PROJ-XXX: <step description>`
4. Update the ticket's "Files Modified" section
5. Append to the ticket's Log
6. Report completion — ready for `/verify`

**No human interruption** once started. The plan was already approved.

#### `/verify`

**Purpose:** Challenge the implementation against the test plan and acceptance criteria.

**Input:** The `test-plan.md` in the active ticket's directory + the implementation on the worktree.
**Output:** Pass/fail verdict with details.
**Behavior:**
1. Read `test-plan.md`
2. Run all tests (both the ones from implementation and any additional from the test plan)
3. Verify each test case passes
4. Check the coverage map: every acceptance criterion must be covered by at least one passing test
5. Walk through each acceptance criterion in the ticket and mark `- [x]` or explain why it fails
6. Render verdict:
   - **Pass:** All criteria met, all tests green → ready for `/commit`
   - **Fail:** List what's broken, suggest fixes → back to `/implement` or `/plan`

#### `/commit`

**Purpose:** Finalize the work — merge the worktree, clean up, complete the ticket.

**Input:** The active ticket in `ongoing/` with a passing `/verify`.
**Output:** Clean merge into main, ticket moved to `completed/`.
**Behavior:**
1. Verify `/verify` passed (all criteria checked)
2. Merge the worktree branch into main (or squash, depending on preference)
3. Clean up the worktree
4. Move `tickets/ongoing/PROJ-XXX/` to `tickets/completed/PROJ-XXX/`
5. Update frontmatter: `status: completed`, `updated: <now>`
6. Add log entry: completion timestamp
7. Final commit with all ticket metadata changes

---

## 4. Decisions Already Made

These decisions were discussed and agreed upon. Do not revisit them.

| # | Decision | Rationale |
|---|----------|-----------|
| D-1 | Artifacts (implementation-plan.md, test-plan.md) live inside the ticket's subdirectory (`tickets/ongoing/PROJ-XXX/`) | Everything co-located. When the ticket moves, artifacts move with it. |
| D-2 | Human validation happens at the `/plan` stage only | Once the plan is approved, `/implement` runs autonomously. No mid-implementation interruptions. |
| D-3 | `/implement` works in a git worktree with intermediate commits | Isolation from main. If verification fails, main is untouched. Intermediate commits provide granular history. |
| D-4 | On `/verify` pass: merge worktree into main. On fail: stay on branch, iterate. | Clean main branch. Failed work stays isolated until fixed. |
| D-5 | This is a standalone project, not embedded in another repo | Deployable to any project. Parameterized prefix (PROJ- is a placeholder). |
| D-6 | No LangGraph dependency | The file system is the state. Git is the persistence. Slash commands are the nodes. A Mermaid state diagram documents the transitions. LangGraph adds complexity without proportional value for this linear-with-one-branch pipeline. |
| D-7 | `/analyze` always targets the first ticket on the roadmap | No manual selection needed for the happy path. The roadmap is the priority queue. |
| D-8 | A state diagram (Mermaid) will document command transitions — useful for both humans and agents | Build it when the commands are stable, not before. |

---

## 5. Configuration (Parameterization)

The system must be configurable per-project. A config file at install:

```yaml
# Ticket workflow configuration
prefix: "PROJ"           # Ticket ID prefix (PROJ-001, PROJ-002, ...)
digits: 3                # Zero-padding width
tickets_dir: "tickets"   # Root directory for tickets
```

All commands, templates, hooks, and scripts read from this config. No hardcoded prefixes.

---

## 6. Repo Structure (Target — in the target project after install)

```
target-project/
├── .claude/
│   └── commands/
│       └── tickets/                     # Slash commands (/tickets:create, etc.)
│           ├── create.md
│           ├── analyze.md
│           ├── split.md
│           ├── schedule.md
│           ├── schedule-batch.md
│           ├── plan.md
│           ├── implement.md
│           ├── verify.md
│           └── commit.md
│
├── .tickets/                            # System files (rm -rf to uninstall)
│   ├── config.yml                       # Parameterization (prefix, paths)
│   ├── TEMPLATE.md                      # Ticket template
│   ├── hooks/
│   │   └── verify-ticket-completion.sh
│   └── agents/
│       └── ticket-analyzer.md           # Complexity analysis agent
│
├── tickets/                             # Ticket data
│   ├── backlog/
│   ├── planned/
│   │   └── roadmap.md
│   ├── ongoing/
│   ├── completed/
│   └── rejected/
```

---

## 7. Implementation Tracking

> **Implementation order note:** Phase 2 (scheduling) must be built before Phase 3 (inner loop) because the inner loop commands require tickets to be scheduled first. During bootstrapping, tickets can be moved manually until `/schedule` is available.

### Phase 1: Foundation (completed)
- [x] Repository scaffold (this repo)
- [x] `install.sh` — downloads system files, creates directory structure
- [x] `system/config.yml` — default configuration
- [x] `system/TEMPLATE.md` — ticket template

### Phase 2: Outer Loop (intake & scheduling)
- [ ] `/schedule` command
- [ ] `/analyze` command
- [ ] `/split` command

### Phase 3: Inner Loop (core pipeline)
- [ ] `/plan` command
- [ ] `/implement` command
- [ ] `/verify` command
- [ ] `/commit` command

### Phase 4: Polish
- [ ] Mermaid state diagram
- [ ] End-to-end pipeline test on a sample project
- [ ] Command reference documentation

### Phase 5: Nice-to-have (validation & tooling)
- [ ] Makefile with `verify-ticket` target
- [ ] `verify-ticket-completion.sh` hook
- [ ] `ticket-analyzer.md` agent
- [ ] Pre-commit hook config
- [ ] `/schedule-batch` command
