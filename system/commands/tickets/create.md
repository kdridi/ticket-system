Create one or more tickets from the following description:

$ARGUMENTS

---

Follow these steps precisely:

## 1. Read configuration

Read `.tickets/config.yml` to get the `prefix` (e.g., "PROJ") and `digits` (e.g., 3) values.

## 2. Read the template

Read `.tickets/TEMPLATE.md` to get the ticket template.

## 3. Determine the next available ID

Scan all subdirectories under `tickets/` (backlog, planned, ongoing, completed, rejected) for existing tickets. Look for files matching `{prefix}-{number}.md` and directories matching `{prefix}-{number}/`. Find the highest number. If no tickets exist, start at 0. The next ticket will be highest + 1.

## 4. Analyze the description

Read the description above carefully and determine:

- Does this describe **one concern** or **multiple distinct concerns**?
- For each concern, extract: a concise title, the objective, the context/motivation, concrete acceptance criteria, the type (feature, bugfix, refactor, docs, research, infrastructure), a priority estimate (P0 = critical, P1 = important, P2 = normal), and complexity estimate (small, medium, large).
- If multiple tickets are needed, identify dependencies between them.

**Guidelines for splitting:**
- Split when the description contains distinct deliverables that could be worked on independently.
- Do NOT split just because something is large — split by concern, not by size.
- If in doubt, fewer tickets is better. One well-scoped ticket beats three vague ones.

## 5. Create the ticket(s)

For each ticket, starting from the next available ID:

1. Copy the template content.
2. Replace all placeholders:
   - `__ID__` → the ticket ID (e.g., `PROJ-001`)
   - `__TITLE__` → the derived concise title
   - `__TIMESTAMP__` → current date and time in `YYYY-MM-DD HH:MM:SS` format
3. Fill in the frontmatter fields: `priority`, `type`, `estimated_complexity`.
4. Fill in the body sections: Objective, Context, Acceptance Criteria (as `- [ ]` checkboxes), Technical Approach (if inferable from the description).
5. Set `dependencies` in frontmatter if this ticket depends on another ticket being created in the same batch.
6. Write to `tickets/backlog/{ticket_id}.md`.

## 6. Report

Summarize what was created:
- List each ticket: ID, title, type, priority, complexity
- Note any dependencies between tickets
- State the file paths created
