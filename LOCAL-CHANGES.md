# Local changes on branch `my-changes`

Base: `origin/master` at `4b399c39a6`, the merge of [upstream PR #8961](<https://github.com/deepseek-ai/deepseek-harness/pull/8961>). These customizations are not intended for upstream.

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
| `document-convert` | Requires the Web profile to have the local `dsh-document-convert` plugin installed. |
| `persona.prefix` | Custom coding-agent instructions without the upstream model-name prefix. |
| Disable plugins | `tool-fs-search`, `tool-jobs`, `tool-schedule`, `command-goal`, `tool-goal`, `plan-mode`, `tool-result-pruner`, `tool-subagent-fork`, `workflow-ptc`, `tool-workflow`, `tool-todo` |
| `compaction-basic` | `thresholdRatio: 0.3`, `headroomTokens: 65536`, `retainRatio: 0.05` |
| `tool-web` | `search: false` |
| `tool-office` | Disabled in standard only; cordis does not include it. |

The Web bundle's [cordis.patch.yml](<packages/bundle/web-app/cordis.patch.yml>) also disables the profile-wide `skill-office` row, which removes the `office` skill and `/office` from every preset. `office-kit` stays enabled for sidebar previews.

Watch upstream preset additions, plugin-id changes, and configuration changes in `tool-fs`, `persona`, `compaction-basic`, `tool-web`, and `tool-subagent`.

Instruction discovery uses unmodified upstream code: native `read` discovers nested instructions; patching an unread directory does not. Already loaded instructions still refresh.

## Custom catalog models

[catalogModels](<packages/llm/llm-pi-ai/src/catalog.ts#L217-L244>) adds fallback models listed in `FALLBACK_MODELS`, each copied from the same provider’s own base entry:

| Models | Base | Providers |
| --- | --- | --- |
| `gpt-6.2-astra`, `gpt-6.2-sol` | `gpt-6.1-sol` | `azure`, `github-copilot` |
| `gemini-4-carbon`, `gemini-4-neon`, `gemini-4-hydrogen` | `gemini-4-argon` | every provider listing `gemini-4-argon` with that exact id: currently `github-copilot`, `google`, `google-vertex`, `opencode` |

The entries inherit the base’s protocol, limits, reasoning capabilities, input modalities, and pricing; these values are not independently verified. Leave `api` unset on `azure` to use native Azure Responses. The corresponding Azure deployments must already exist.

Existing upstream entries take precedence. Remove a fallback when the installed pi-ai catalog supplies the model for that provider. If a provider no longer lists the base, no fallback is added for it. Watch the catalog lookup, its callers, and pi-ai’s provider catalogs when pulling upstream. [Regression tests](<packages/llm/llm-pi-ai/tests/catalog.spec.ts#L496-L522>) check each model against its provider’s installed base metadata.

## Local restart helper

[restart-web.sh](<restart-web.sh>) restarts `pnpm dsh web --no-open` inside a `screen` session.

## Verification after merging

```sh
pnpm exec vitest run packages/context/agent-instructions packages/fs/tool-fs
pnpm exec vitest run packages/llm/llm-pi-ai/tests/catalog.spec.ts packages/llm/llm-pi-ai/tests/catalog-provider-ids.spec.ts
pnpm run build:artifacts
pnpm run build:check
```

Run `npm run check` in every local plugin, restart Web, and verify a new session uses the intended tools.
