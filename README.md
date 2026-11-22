# Buzz agents dev container

Runtime environment for the Buzz agents, managed by `dev` (dev-cli).

## What is set up

| Item | Value |
|---|---|
| dev workspace | `buzz` (provider `local`) |
| container | `buzz-agents` |
| mode | `unprotected` (`.git` writable, so agents can commit and use worktrees) |
| host folder | `/home/dnguyen/Projects/buzz-containers` |
| tools | `gh`, `claude-code`, `mise`, `claude-agent-acp` (+ `node`, required by Claude) |
| Buzz CLI mount | `/usr/local/bin/buzz` (read-only, from `.dev/buzz/buzz-linux-amd64`) |
| harness | `~/.local/bin/dev-acp` |
| devcontainer CLI | `devcontainer` 0.91.0 (global) |

The container is built from this project's `.devcontainer/` configuration, not
from a generated one. dev merges in its own state-volume mount and lifecycle
settings; the file itself is never edited.

`unprotected` mode lets the agent write `.git` and create worktrees. To make
`.git` read-only again:

```sh
dev container rebuild buzz-agents --workspace buzz --mode guarded
```

Verified inside `buzz-agents`:

| Tool | Version / path |
|---|---|
| gh | 2.105.0 — `/usr/bin/gh` |
| claude | 2.1.330 — `/usr/local/share/nvm/versions/node/v26.13.1/bin/claude` |
| mise | 2026.11.12 — `/usr/local/bin/mise` |
| node / npm | v26.13.1 / 11.20.0 |
| buzz | `/usr/local/bin/buzz` |
| claude-agent-acp | `/usr/local/share/nvm/versions/node/v26.13.1/bin/claude-agent-acp` |

Workspace folder inside the container: `/workspaces/buzz-containers`.

## Hook it into Buzz Desktop

Prerequisites:

- The container is running: `dev container list --workspace buzz` shows
  `buzz-agents`.
- The harness exists and is executable: `~/.local/bin/dev-acp`.
- The Buzz relay is reachable from **inside** the container.

Do this once per agent:

1. Open Buzz Desktop and create (or open) the agent.
2. Set **ACP command** to **Buzz ACP**. The harness is not the ACP command.
3. Set the agent **runtime / custom harness** to the harness path:
   ```
   /home/dnguyen/.local/bin/dev-acp
   ```
4. Add these **agent environment variables**:
   - `DEV_ACP_CONTAINER=buzz-agents` — required
   - `DEV_ACP_WORKSPACE=buzz` — required
   - `DEV_ACP_AGENT=claude` — optional, defaults to `claude`
   - `DEV_ACP_TRACE=/tmp/acp-buzz-agents.log` — optional, defaults to
     `/tmp/acp-<container>.log`
5. Start the agent.
6. @mention it in a channel and send a message.

The harness runs `dev` by its absolute path and serves the container's agent over
ACP with `--integration buzz`. It passes `BUZZ_PRIVATE_KEY`, `BUZZ_AUTH_TAG`,
`BUZZ_RELAY_URL`, and `BUZZ_OUTPUT_FORMAT` from the agent environment when set.

> `BUZZ_RELAY_URL` must be reachable from **inside** the container. A relay on the
> host's `127.0.0.1` is not.

### If the agent does not start

| Symptom | Fix |
|---|---|
| Harness exits 2 naming `DEV_ACP_CONTAINER` or `DEV_ACP_WORKSPACE` | Add the missing variable to the agent environment |
| “Cannot connect to the Docker daemon” | Desktop ignores your shell env; with Podman run `docker context use podman` |
| Adapter not found | Rebuild: `dev container rebuild buzz-agents --workspace buzz --accept-config` |
| Agent starts but cannot reply in Buzz | Check `buzz` is at `/usr/local/bin/buzz` in the container |

### Lifecycle

- Starting the agent in Desktop runs `dev container acp`, which starts the
  container if it is stopped.
- Stop the container for good only after stopping its agents in Desktop.
- A rebuild kills running agents; `buzz-acp` starts them again once the
  container is up.

## Common commands

```sh
# workspace and container status
dev workspace use buzz
dev container list --workspace buzz

# shell into the container
dev container shell buzz-agents --workspace buzz

# rebuild after editing .devcontainer/ or agents.yaml; kills running agents
dev container rebuild buzz-agents --workspace buzz --accept-config

# stop for good: stop the agents in Buzz Desktop first, then
dev container stop buzz-agents --workspace buzz
```

`dev` shells out to the `devcontainer` CLI. It is installed globally
(`/home/dnguyen/.nvm/versions/node/v26.13.1/bin/devcontainer`, 0.91.0).

## Project configuration

- `.devcontainer/devcontainer.json` — image, Features (`gh`, `mise`, Node,
  Claude Code, ACP adapter, full Python), state env/mount, and
  `postCreateCommand`.
- `.devcontainer/agents.yaml` — the Claude plugins installed on create/rebuild.
  Edits take effect on the next rebuild.
- `.devcontainer/CLAUDE.md` — container-global Claude instructions, copied to
  `$CLAUDE_CONFIG_DIR/CLAUDE.md` on create/rebuild.
- `.devcontainer/statusline.sh` — the host's status line as a script.
- `.devcontainer/claude-settings.json` — the `statusLine` definition.
- `.devcontainer/post-create.sh` — merges the status line into
  `$CLAUDE_CONFIG_DIR/settings.json` while preserving `enabledPlugins`.

`agents.yaml` has no `statusLine` key (its Claude section accepts only
`marketplaces`, `plugins`, `skills`, and `mcp`), which is why the status line is
seeded through Claude's own settings file at create time.

The image installs `python3`, `python3-pip`, and `python3-venv` via the
`apt-get-packages` Feature. The base image only ships `python3-minimal`, whose
missing `libpython3.12-stdlib` makes `import json` fail; the `security-guidance`
plugin's `UserPromptSubmit` hook then reports
`ModuleNotFoundError: No module named 'json'`.

The container-global `CLAUDE.md` is installed as
`/var/dev-state/claude/CLAUDE.md` (`$CLAUDE_CONFIG_DIR/CLAUDE.md`), so it applies
to every repository in the container. Claude Code concatenates it with each
repo's own `CLAUDE.md`, and the repo instructions load after the global ones.
The state volume keeps it across rebuilds; edit `.devcontainer/CLAUDE.md` rather
than the copy in the container, which is replaced on create/rebuild.

## Workspace environment

Set with `dev workspace set`; dev injects them into every command and agent:

```sh
dev workspace show buzz
```

Configured non-secret values:

| Key | Value |
|---|---|
| `ANTHROPIC_BASE_URL` | `https://llm.llmxyz.net` |
| `ANTHROPIC_MODEL` | `cloud.deepseek-v4.1-flash` |
| `ANTHROPIC_SMALL_FAST_MODEL` | `cloud.glm-5.3-flash` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `cloud.glm-5.3-flash` |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `cloud.deepseek-v4.1-flash` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `cloud.deepseek-v4.1-flash` |
| `ANTHROPIC_DEFAULT_FABLE_MODEL` | `cloud.kimi-k3.1-pro` |
| `CLAUDE_CODE_MAX_CONTEXT_TOKENS` | `1048576` |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `1` |
| `GIT_AUTHOR_NAME` | `Buzz Agent` |
| `GIT_AUTHOR_EMAIL` | `duy.nguyen.public@gmail.com` |
| `GIT_COMMITTER_NAME` | `Buzz Agent` |
| `GIT_COMMITTER_EMAIL` | `duy.nguyen.public@gmail.com` |

`ANTHROPIC_API_KEY` and `GH_TOKEN` are also set, but to keyring specs — see
below.

## Git identity and signing

Identity:

- `user.name` / `user.email` in the persistent global gitconfig
  (`/var/dev-state/gitconfig`): `Buzz Agent <duy.nguyen.public@gmail.com>`.
- dev also injects `GIT_AUTHOR_*` / `GIT_COMMITTER_*`, which override git
  config, so the workspace setting carries the same values.

Signing:

- Private key: `.dev/ssh/buzz-signing` (`0600`, gitignored), visible in the
  container at `/workspaces/buzz-containers/.dev/ssh/buzz-signing`.
- Public key: `.dev/ssh/buzz-signing.pub`; register it on GitHub as a
  **Signing Key** (not an Authentication Key).
- Allowed signers: `.dev/ssh/allowed_signers`.
- Global config:

  ```sh
  gpg.format ssh
  user.signingkey /workspaces/buzz-containers/.dev/ssh/buzz-signing
  commit.gpgsign true
  tag.gpgsign true
  gpg.ssh.allowedSignersFile /workspaces/buzz-containers/.dev/ssh/allowed_signers
  ```

Auth and repository behavior:

- HTTPS through `gh` and `GH_TOKEN`:
  `credential.https://github.com.helper = !gh auth git-credential`
- Existing SSH remotes are rewritten to HTTPS:
  `url.https://github.com/.insteadOf = git@github.com:`
- `.dev/gitignore` contains `.worktrees/` and is set as `core.excludesFile`.
- `pull.rebase` and `fetch.prune` are enabled.

Verify signing without touching a real repository:

```sh
dev container exec buzz-agents --workspace buzz -- bash -lc '
  d=$(mktemp -d); cd "$d"; git init -q
  git commit --allow-empty -m test >/dev/null
  git log --show-signature -1
'
```

Expect `Good "git" signature` and `Author: Buzz Agent`.

### Rotating the signing key

```sh
rm .dev/ssh/buzz-signing .dev/ssh/buzz-signing.pub
ssh-keygen -t ed25519 -C "buzz-agents signing" -N "" -f .dev/ssh/buzz-signing
chmod 600 .dev/ssh/buzz-signing
printf '%s namespaces="git" %s\n' 'duy.nguyen.public@gmail.com' \
  "$(cat .dev/ssh/buzz-signing.pub)" > .dev/ssh/allowed_signers
```

Then add the new public key on GitHub as a Signing Key and remove the old one.
The git config keeps the same path, so no config change is needed.

## API key and secret backends

dev-cli `v0.23.0-4-gf2485ba` (PR #62) resolves four backends:

| Spec | Backend | Works on this Ubuntu host? |
|---|---|---|
| `literal:VALUE` | value as written (stored in dev's DB) | yes |
| `keyring:SERVICE` | freedesktop Secret Service, bare `service` attribute | yes |
| `keyring:K=V,K=V` | freedesktop Secret Service, several attributes | yes |
| `keychain:SERVICE` | macOS `security` command | no — `security` is not installed |
| `op://vault/item/field` | 1Password CLI `op` | no — `op` is not installed |

The workspace uses the multi-attribute keyring form:

```sh
dev workspace set ANTHROPIC_API_KEY \
  'keyring:service=litellm,username=dnguyen-nuc'
```

That matches the host entry `secret-tool lookup service litellm username
dnguyen-nuc`. The spec is stored in dev's DB; the value resolves on every
launch, and `dev workspace show buzz` prints only the spec. Never put the key in
this repo or in `.devcontainer/agents.yaml`.

GitHub uses the same mechanism:

```sh
dev workspace set GH_TOKEN 'keyring:service=github,username=buzz-agents'
```

Verified without exposing the token:

```sh
dev container exec buzz-agents --workspace buzz -- gh auth status
```

### Storing or updating a secret

The value lives in the keyring; dev stores only the reference. Use a no-echo
prompt so the secret stays out of shell history:

```sh
read -rsp 'GitHub PAT: ' PAT
printf '%s' "$PAT" | secret-tool store \
  --label='Buzz agents token' service github username buzz-agents
unset PAT
```

Re-running `secret-tool store` with the same attributes replaces the stored
value. No `dev workspace set` is needed: the spec is unchanged, and dev resolves
the new value on the next launch. Restart the agent in Buzz Desktop to pick it
up.

For the Anthropic key:

```sh
read -rsp 'Anthropic API key: ' KEY
printf '%s' "$KEY" | secret-tool store \
  --label='litellm' service litellm username dnguyen-nuc
unset KEY
```

To change the lookup attributes instead, update the workspace spec:

```sh
dev workspace set GH_TOKEN 'keyring:service=github,username=buzz-agents'
```

## Regenerating the harness

```sh
dev container acp --workspace buzz --integration buzz --print-harness \
  > ~/.local/bin/dev-acp
chmod +x ~/.local/bin/dev-acp
```

Regenerate if `dev` moves or the flags passed to `--print-harness` change.

## Files

- `agents/` — Chief, Assistant, Communicator, Researcher instructions.
- `.devcontainer/` — devcontainer.json, agents.yaml, status-line seeding.
- `.dev/buzz/buzz-linux-amd64` — Linux amd64 Buzz CLI (checksum verified).
- `.dev/buzz/SHA256SUMS` — checksum for the Buzz CLI.
- `.dev/ssh/` — signing private key, public key, and allowed signers
  (gitignored; back this up).
- `.dev/gitignore` — global excludes source, containing `.worktrees/`
  (gitignored).
- `~/.local/bin/dev-acp` — generated ACP harness (outside this repo).
