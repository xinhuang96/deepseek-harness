# Local changes on branch `my-changes`

Base: `origin/master` at `687f282e86` (release dsh 0.2.1-rc.2). All changes below are local customizations, not intended for upstream.

## How to use this file before `git pull origin master`

Give an AI agent this file and ask: "Check upstream against LOCAL-CHANGES.md." The agent should:

1. `git fetch origin` and list upstream commits since the recorded base: `git log --oneline <base>..origin/master`.
2. For each change below, run `git diff <base> origin/master -- <owned files> <watched files>` and `git log <base>..origin/master -- <same paths>`. Also grep upstream for the "redundant if" keywords, because upstream may add the feature in a different file.
3. Classify each change as one of:
   - **Superseded**: upstream now provides the behavior (see "Upstream makes it redundant if"). Recommend dropping the local change and adopting upstream's version.
   - **Broken**: upstream changed something the change relies on (see "Breaks if"). Describe the required rework.
   - **Conflict only**: textual conflict in an owned file with no semantic impact. Recommend a resolution.
   - **Unaffected**.
4. Report the classification per change and wait for approval before merging. After merging, run the verification commands below and update the base SHA at the top of this file.
5. Also check the local plugins in `~/.dsh/plugins` against the same upstream range by following the "Upstream check" section of `~/.dsh/plugins/AGENTS.md`, and include their classification in the report.

Owned files are files this branch edits. Watched files are upstream files this branch does not edit but whose behavior it depends on.

## Change 1: Synthetic `claude-haiku-5.5` for GitHub Copilot

**Goal:** expose `github-copilot/claude-haiku-5.5`, which the pi-ai builtin catalog does not list, by cloning the `claude-opus-5.5` entry.

**Owned files:** `packages/llm/llm-pi-ai/src/catalog.ts` (`catalogModels`).

**Watched files:** the `@earendil-works/pi-ai` version in `packages/llm/llm-pi-ai/package.json` and `pnpm-lock.yaml`.

**Upstream makes it redundant if:** the builtin catalog lists `claude-haiku-5.5` for `github-copilot`. The code already skips the clone then; delete it. Check with `rg -l "claude-haiku-5.5" node_modules/.pnpm/@earendil-works+pi-ai*/`.

**Breaks if:** `claude-opus-5.5` leaves the catalog; the clone then silently disappears. The clone copies Opus's context window, cost, and capabilities, which may be wrong for Haiku.

## Change 2: Nested AGENTS.md discovery for Copilot-style file tools

**Goal:** `agent-instructions` loads directory-scoped AGENTS.md files when a file is touched. Upstream only recognizes `read`/`write`/`edit` with `file_path`; this adds `view` (`path`) and `apply_patch` (paths from `*** Add File:`, `*** Update File:`, `*** Delete File:`, and `*** Move to:` lines in `input`), the tools `dsh-copilot-sdk-tools` provides.

**Owned files**
- `packages/context/agent-instructions/src/index.ts` — `filePathsFromExecution`.
- `packages/context/agent-instructions/tests/agent-instructions.spec.ts`

**Upstream makes it redundant if:** upstream derives touched paths from tool metadata (for example a tool-declared path extractor) or recognizes `view`/`apply_patch` itself.

**Breaks if:** the tool-execution hooks or `ToolExecution` fields change, or `dsh-copilot-sdk-tools` renames its tools or arguments.

## Change 3: `standard` and `cordis` Web presets customized

**Goal:** make both Web presets use the Copilot SDK file tools, a Claude-Code-style persona, more aggressive compaction, and a reduced tool set.

**Owned files:** `packages/bundle/web-app/presets/standard.patch.yml`, `packages/bundle/web-app/presets/cordis.patch.yml`. The edits are identical in both.

| Edit | Detail |
| --- | --- |
| Add `copilot-sdk-tools` | `dsh-copilot-sdk-tools` with `apply_patch`, `view`, `glob`, `rg`. External plugin at `~/.dsh/plugins/dsh-copilot-sdk-tools`, not in this repo; the presets fail to mount if the profile lacks it. |
| Replace `persona.prefix` | Long system-prompt text. Drops upstream's `You are a coding agent powered by the {{model}} model.`, so the model name is no longer in the prompt. |
| Disable plugins | `tool-fs`, `tool-fs-search`, `tool-jobs`, `tool-schedule`, `command-goal`, `tool-goal`, `plan-mode`, `tool-result-pruner`, `tool-subagent-fork`, `workflow-ptc`, `tool-workflow`, `tool-todo` |
| `compaction-basic` | `thresholdRatio: 0.3`, `headroomTokens: 65536`, `retainRatio: 0.05` |
| `tool-web` | `search: false` |

**Watched:** upstream edits to these two YAML files (plugins newly added to the presets are enabled by default and need a keep/disable decision), renamed plugin ids, and config-key renames in `persona`, `compaction-basic`, `tool-web`, and `tool-subagent`.

**Alternative:** move these edits into a personal preset or profile overlay under `~/.dsh` instead of the shipped preset files. Upstream preset edits then never conflict, and only config-key renames need checking.

## Local restart helper

- `restart-web.sh` restarts `pnpm dsh web --no-open` inside a `screen` session. It does not depend on upstream code.

## Verification after merging

```sh
pnpm exec vitest run packages/context/agent-instructions packages/llm/llm-pi-ai
pnpm run typecheck
pnpm run build:artifacts   # then ./restart-web.sh and smoke-test the Web GUI
pnpm run build:check
```

State at base `1517a4dbca`: 598 passed, 0 failed; typecheck, build:artifacts, build:check, and all 10 local plugin check scripts passed. Web restart and live GUI smoke test remain pending.
