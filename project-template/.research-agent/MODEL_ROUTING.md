# Research Agent Model and Tool Routing

This launcher-managed file is referenced by the managed block in project AGENTS.md.

## Model tiers

| Tier | Model | Reasoning | Boundary |
|---|---|---|---|
| strategic | Sol | xhigh/high | Main-agent research strategy, key judgement, evidence review, and final acceptance |
| support | Terra | medium | Read-only bounded extraction, scanning, evidence inventory, and deterministic checks |
| economy | Luna | low | Read-only mechanical formatting of complete and confirmed content |

Subagents may not delegate. The main agent reviews every result and owns final research judgement.

## Tool and token controls

- Prefer Codex built-in reads, searches, and precise patches; use rg for repository search and git diff for version inspection.
- Prefer PowerShell for Windows launchers, registry, environment, system paths, and CMD/PowerShell compatibility.
- Prefer Python for data cleaning, CSV/JSON/Excel, research computing, plotting, and reusable cross-platform batches.
- Limit search scope and terminal output; write large results to files and keep only status, paths, counts, summaries, and errors on screen.
- Keep verbose logs off by default; run the smallest relevant test first and the full suite last.
- Change diagnostic method after two consecutive failures of the same class; do not retry blindly.
