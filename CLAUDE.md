# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリの位置づけ

Claude Code Workshop のサンプルハーネス。
アプリケーションコード（`package.json` / `src/` 等）は意図的に置いていない。
`.claude/` 配下の設定ファイルそのものが学習対象であり、Claude Code の 7 要素（settings / statusLine / CLAUDE.md / Rules / Hooks / Subagents / Skills / MCP）に触れる構成になっている。

## ハーネスのアーキテクチャ

3 層で防御と支援を構成している。各層は独立しており、別レイヤを変更したくなったときは波及範囲を意識すること。

### 1. 静的設定層 (`.claude/settings.json`, `.mcp.json`)

- `settings.json` で `model` / `statusLine` / `permissions` (allow / ask / deny) を宣言
- `.mcp.json` は HTTP MCP として `context7` を 1 つだけ登録。`enabledMcpjsonServers` は `settings.local.json` 側で許可される
- `settings.local.json` は `.gitignore` 済み。ローカル限定の MCP 有効化フラグなどはここに置く

### 2. 動的フック層 (`.claude/hooks/*.sh`)

すべて bash + `jq`。stdin から Claude Code が JSON を流し込み、stdout で `permissionDecision: deny` を返すと拒否、exit 1 でエラー伝達という共通契約を持つ。

- `pre-tool-use-guard.sh` — Edit / Write 対象が `tsconfig.json` / `.eslintrc*` / lockfile / `*.env` などの保護パターンに該当する場合に `deny` を返す
- `pre-tool-use-branch-guard.sh` — Bash の `git commit` / `git push` を検査し、現在ブランチが `main` / `master` / `develop` / `release/*` なら `deny`
- `post-tool-use-lint.sh` — `.ts/.tsx/.js/.jsx/.mjs/.cjs` 編集後に `npx --no-install eslint --fix` → `npx --no-install prettier --write` を実行。`package.json` や CLI が無ければスキップ（`--no-install` で勝手なインストールを防ぐ）

`jq` が無い環境では各フックは `exit 0` で no-op になる設計。フックを追加するときも同じ契約を踏襲する。

### 3. プロンプト介入層 (`.claude/agents`, `.claude/rules`, `.claude/skills`)

- `agents/` — Subagent 定義。frontmatter の `tools` で権限を絞っている。`researcher` は Read/Glob/Grep のみ（読み取り専用調査）、`code-reviewer` は + Bash で diff を読むがファイル編集はしない
- `rules/` — frontmatter の `paths` glob にマッチするファイルを編集するときに自動でロードされる。`typescript.md` (TS/TSX) と `testing.md` (`*.test.*` / `__tests__/`) の 2 本
- `skills/practicing-tdd/` — `/tdd` で起動する TDD 強制スキル。`SKILL.md` 本体に加え、モック関連で `testing-anti-patterns.md` を参照させる構造

## このリポジトリで作業するときのルール

### 設定ファイル群は「教材」である

`tsconfig.json` / `.eslintrc*` / lockfile / `.env*` への編集は `pre-tool-use-guard.sh` でブロックされる。これは仕様であってバグではない。設定値の議論は差分提示に留め、ユーザーに手動適用を依頼する。

### `main` ブランチで commit / push しない

`pre-tool-use-branch-guard.sh` がブロックする。作業前に `git switch -c <feature-branch>` で feature ブランチへ切り替える（`git checkout` は使わない）。

### Hook スクリプトを編集したら実行権限を確認

新しく clone した直後は実行ビットが落ちている可能性があるため、`chmod +x .claude/hooks/*.sh` を済ませてから動作確認に入る。

### サブエージェントの使い分け

- 「このリポジトリの〜はどう実装されている？」のような調査依頼 → `researcher` に委譲（メインのコンテキストにファイル全文を持ち込まない）
- 「`src/sample.ts` をレビューして」のような完成物のレビュー依頼 → `code-reviewer` に委譲（5 観点 + Must/Should/Nice の構造化レポートが返る）

### TDD スキル

実装系タスク（ハンズオンでは `src/sample.ts` の `greet` や `src/email.ts` の `validateEmail` 追加など）は `/tdd` 経由で起動し、RED → Verify RED → GREEN → Verify GREEN → REFACTOR を踏む。`testing-anti-patterns.md` はモックを書くタイミングで参照される。
