# SDD when `.spec/` exists

If this workspace has a `.spec/` directory:

1. Load and follow the skill `sdd-context`.
2. YAGNI: do not implement future Steps or PBIs.
3. One active `PBI-*.md` in `.spec/features/` (not `backlog/` or `archive/`).
4. One Step per `exec-step`. Use the SDD skills as gates; do not mix them.

If there is no `.spec/`, ignore this block.
