# claude-code-workshop-202604

Claude Code Workshop Section 02 のハンズオン用サンプルハーネス。Claude Code の主要 7 要素（settings / statusLine / CLAUDE.md / Rules / Hooks / Subagents / Skills / MCP）を 1 つのリポジトリで体験できる構成になっている。

## 目次

- [プロジェクト概要](#プロジェクト概要)
- [対象ユーザー](#対象ユーザー)
- [前提条件](#前提条件)
- [使い方](#使い方)
  - [インストール](#インストール)
  - [設定](#設定)
  - [実行](#実行)
- [リポジトリ構成](#リポジトリ構成)
- [関連ドキュメント](#関連ドキュメント)

## プロジェクト概要

`claude-code-workshop-202604` を使うと、Claude Code を「ガードレール付きの開発エージェント」として運用するための実践的なハーネス構成を学べる。

このハーネスは 3 層に分かれている。

- 静的設定層: `.claude/settings.json` と `.mcp.json` で `model` / `statusLine` / `permissions` / MCP サーバーを宣言的に管理する
- 動的フック層: `.claude/hooks/*.sh` の bash + `jq` スクリプトで、設定ファイル保護や保護ブランチへの直接 commit / push のブロックを行う
- プロンプト介入層: `.claude/agents` / `.claude/rules` / `.claude/skills` で、サブエージェント・コーディングルール・TDD スキルを通じてエージェントの挙動を誘導する

ワークショップ受講者は「`src/sample.ts` の `greet` を TDD で実装する」「`src/email.ts` の `validateEmail` を追加する」など、実装課題を `/tdd` スキル経由で進めながら、各レイヤがどう作用するかを観察する。

なお、本リポジトリは意図的にアプリケーションコード（`package.json` / `src/` 等）を含めていない。`.claude/` 配下の設定ファイルそのものが学習対象である。

## 対象ユーザー

このプロジェクトは、Claude Code の挙動をプロジェクトレベルでカスタマイズしたいエンジニアおよびハンズオン受講者向け。具体的には以下のような目的を持つ人を想定している。

- Claude Code の `settings.json` / Hooks / Subagents / Skills / MCP の構成方法をハンズオンで把握したい
- TDD などの開発プロセスをエージェントに強制する仕組みを実例で学びたい
- 「保護ブランチでの commit 禁止」「重要設定ファイルへの直接編集禁止」といったガードレールの実装パターンを参考にしたい

## 前提条件

`claude-code-workshop-202604` を使用するには、以下が必要になる。

- [Claude Code](https://claude.com/claude-code) CLI（最新版を推奨）
- `jq` 1.6 以降
  - macOS: `brew install jq`
  - フックは `jq` 不在時に no-op で素通りする設計のため、未インストールでもエラーにはならないが、ガードレールが効かなくなるためインストールを強く推奨
- `bash` 4.0 以降
- `git` 2.30 以降
- Node.js v24 以降（ハンズオン中に TypeScript ファイルを編集する場合に lint / format フックが利用するため）
- `pnpm` または `npm` v11 以降（lint / format フックは `npx --no-install` で起動するため、ローカルにインストール済みである必要はない）

## 使い方

### インストール

1. リポジトリをクローン

    ```bash
    git clone https://github.com/sakai-classmethod/claude-code-workshop-202604.git
    cd claude-code-workshop-202604
    ```

2. フックスクリプトに実行権限を付与

    新規 clone 直後は実行ビットが落ちている可能性があるため、必ず実行権限を付与する。

    ```bash
    chmod +x .claude/hooks/*.sh
    ```

3. 作業ブランチを切る

    `main` ブランチでは `pre-tool-use-branch-guard.sh` が `git commit` / `git push` をブロックするため、必ず feature ブランチへ切り替える。`git checkout` ではなく `git switch` を使うこと。

    ```bash
    git switch -c feature/handson-001
    ```

### 設定

1. `.claude/settings.json` を確認

    `model` / `permissions` / `hooks` がリポジトリ単位で宣言されている。ハンズオン中に編集対象になることはほぼないが、内容に目を通しておく。

2. （任意）`.claude/settings.local.json` で MCP を有効化

    `.mcp.json` には HTTP MCP として `context7` が登録されている。ローカルで有効化したい場合は `.claude/settings.local.json` の `enabledMcpjsonServers` に追加する。`.claude/settings.local.json` は `.gitignore` 済みのため、個人ごとの好みで設定して問題ない。

3. （任意）statusLine の動作確認

    `.claude/statusline.sh` がモデル名やコンテキスト残量を表示する。Claude Code を起動した時点で自動的に有効になる。

### 実行

1. リポジトリ直下で Claude Code を起動

    ```bash
    claude
    ```

2. ハンズオン課題を `/tdd` スキル経由で開始

    `src/sample.ts` の `greet` 関数を実装する場合の例。

    ```text
    /tdd src/sample.ts に greet(name: string) を追加してください
    ```

    Claude Code は `RED → Verify RED → GREEN → Verify GREEN → REFACTOR` のサイクルを強制する。

3. 調査やレビューはサブエージェントへ委譲

    - 調査依頼: 「このリポジトリの〜はどう実装されている？」のような問い合わせは `researcher`（Read / Glob / Grep のみの読み取り専用）に委譲することで、メインのコンテキストを汚さずに済む
    - レビュー依頼: 「`src/sample.ts` をレビューして」といった完成物のレビューは `code-reviewer` に委譲すると、5 観点 + Must / Should / Nice の構造化レポートが返る

## リポジトリ構成

| パス | 役割 |
| :--- | :--- |
| `.claude/settings.json` | モデル / 権限 / Hooks の宣言。リポジトリ全体に適用される |
| `.claude/settings.local.json` | ローカル限定の上書き設定。`.gitignore` 済み |
| `.claude/statusline.sh` | カスタム statusLine。モデル名や残コンテキストを表示 |
| `.claude/hooks/pre-tool-use-guard.sh` | `tsconfig.json` / `.eslintrc*` / lockfile / `*.env` 等への Edit / Write をブロック |
| `.claude/hooks/pre-tool-use-branch-guard.sh` | `main` / `master` / `develop` / `release/*` での `git commit` / `git push` をブロック |
| `.claude/hooks/post-tool-use-lint.sh` | `.ts` / `.tsx` / `.js` 等の編集後に `eslint --fix` → `prettier --write` を実行 |
| `.claude/agents/researcher.md` | 読み取り専用の調査用サブエージェント定義 |
| `.claude/agents/code-reviewer.md` | 構造化レビューを返すサブエージェント定義 |
| `.claude/rules/typescript.md` | TS / TSX 編集時に自動ロードされるコーディング規約 |
| `.claude/rules/testing.md` | `*.test.*` / `__tests__/` 編集時に自動ロードされるテスト規約 |
| `.claude/skills/tdd/SKILL.md` | `/tdd` で起動する TDD 強制スキル本体 |
| `.claude/skills/tdd/testing-anti-patterns.md` | モックを書くタイミングで参照されるアンチパターン集 |
| `.mcp.json` | HTTP MCP として `context7` を登録 |
| `CLAUDE.md` | リポジトリ単位のプロジェクトメモリ。ハーネス全体の運用ルールを記述 |

## 関連ドキュメント

- [Claude Code 公式ドキュメント](https://docs.claude.com/en/docs/claude-code/overview) - Claude Code の基礎概念と CLI リファレンス
- [Claude Code Hooks リファレンス](https://docs.claude.com/en/docs/claude-code/hooks) - PreToolUse / PostToolUse などのフックイベント仕様
- [Claude Code Subagents ガイド](https://docs.claude.com/en/docs/claude-code/sub-agents) - サブエージェントの定義方法と権限制御
- [Claude Code Skills ガイド](https://docs.claude.com/en/docs/claude-code/skills) - Skill の作成・配布方法
- [Model Context Protocol](https://modelcontextprotocol.io/) - `.mcp.json` で利用する MCP の仕様
- [CLAUDE.md](./CLAUDE.md) - 本リポジトリのアーキテクチャと運用ルールの詳細
