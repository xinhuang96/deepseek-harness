# Local changes on branch `my-changes`

Base: `origin/master` at the merge of [upstream PR #7873](<https://github.com/deepseek-ai/deepseek-harness/pull/7873>). These customizations are not intended for upstream.

## Before pulling upstream

1. Fetch `origin` and compare the recorded base with `origin/master`, including commits and diffs for the files and dependencies below.
2. Check local plugins against the same range using the "Upstream check" section of `~/.dsh/plugins/AGENTS.md`.
3. Report each customization as superseded, broken, conflict only, or unaffected. Wait for approval before merging; leave conflicts unresolved for user review.
4. After merging, verify below and update the base reference.

## Web presets

Both [standard](<packages/bundle/web-app/presets/standard.patch.yml>) and [cordis](<packages/bundle/web-app/presets/cordis.patch.yml>) have the same customizations.

| Edit | Detail |
| --- | --- |
| `tool-fs` | Enabled with `applyPatch: true`, `write: false`, `edit: false`; native reads remain enabled. |
| Add `document-convert` | Requires the profile to provide external `dsh-document-convert` from `~/.dsh/plugins/dsh-document-convert`. |
| `persona.prefix` | Custom coding-agent instructions without the upstream model-name prefix. |
| Disable plugins | `tool-fs-search`, `tool-jobs`, `tool-schedule`, `command-goal`, `tool-goal`, `plan-mode`, `tool-result-pruner`, `tool-subagent-fork`, `workflow-ptc`, `tool-workflow`, `tool-todo` |
| `compaction-basic` | `thresholdRatio: 0.3`, `headroomTokens: 65536`, `retainRatio: 0.05` |
| `tool-web` | `search: false` |

Watch upstream preset additions, plugin-id changes, and configuration changes in `tool-fs`, `persona`, `compaction-basic`, `tool-web`, and `tool-subagent`.

Instruction discovery uses unmodified upstream code: native `read` discovers nested instructions; patching an unread directory does not. Already loaded instructions still refresh.

## Local restart helper

[restart-web.sh](<restart-web.sh>) restarts `pnpm dsh web --no-open` inside a `screen` session.

## Verification after merging

```sh
pnpm exec vitest run packages/context/agent-instructions packages/fs/tool-fs
pnpm run build:artifacts
pnpm run build:check
```

Run `npm run check` in every local plugin, restart Web, and verify a new session uses the intended tools.
