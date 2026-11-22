# Container conventions

- All checkouts live under `/workspaces/`. Start work from the repository root.
- Git identity and commit signing are preconfigured. Do not change them.
- For feature work, create a worktree inside the repository:
  `git worktree add .worktrees/<slug> -b agent/<slug>`
- Run tests and commits from inside that worktree.
- Use `gh` for GitHub; it already has `GH_TOKEN`. Never re-authenticate.
- Never print, commit, copy, or paste tokens or private keys.
- If a repository has its own `CLAUDE.md`, follow it for repo-specific commands
  and conventions.
- Before reporting done: run the tests, check `git status`, and summarize the
  diff.
