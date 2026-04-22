# Ask the Duck — Source Documents

This folder is where you drop the raw **Pool Duck FDD** and
**Franchise Operations Manual** so Claude Code can extract the
tech-relevant sections into the app playbook.

## How to use this folder

1. Create a `docs/source/` subfolder locally and drop the PDFs (or DOCX)
   inside. Typical filenames:
   - `source/PoolDuck-FDD-<year>.pdf`
   - `source/PoolDuck-FOM-<year>.pdf`
2. `source/` is listed in `docs/.gitignore`, so the raw documents will
   **never** be committed to the repo. They stay on your machine.
3. Ask Claude Code to extract the playbook. The output lives in
   `AskTheDuck/AskTheDuck/Resources/playbook.md` — the only file that
   ships inside the app.
4. Legal / ops reviews the generated `playbook.md` before you cut a
   TestFlight build.

## What Claude extracts (and what it won't)

Claude pulls only the sections that govern **field-technician decisions**:

- Repair process workflow (the "Pool Duck way" diagnostic order).
- Audience / voice rules (tech-to-tech tone, not homeowner-facing).
- Escalation triggers and handoffs to the office.
- Safety policy and non-negotiables.
- Markup / pricing policy and local-market adjustment guidance.
- Photo / documentation requirements on warranty and billable jobs.

Claude will NOT copy:

- Investor disclosures, Item-by-Item FDD content, financial statements,
  or biographies.
- Anything that looks like regulated representation or earnings claims.
- Franchisee personal info.

If you see FDD-style regulated language in `playbook.md`, flag it and
we'll regenerate — the derived playbook should cite the FOM (internal
ops) almost exclusively.

## Per-franchise overrides (future)

Individual franchises that need to override markup, labor rates, or
local rules will eventually get their own overlay file (planned for a
later release). The master `playbook.md` stays the franchise-wide
baseline.
