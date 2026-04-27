---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Coding Rules

このファイルは TypeScript / TSX を編集するときに自動でロードされる。

## 型システム

- `any` を使わない。やむを得ない場合は `unknown` を使い、ナローイングしてから利用する
- 関数の引数と戻り値には明示的な型注釈を付ける（推論可能な内部変数は省略してよい）
- enum は使わない。代わりに `as const` オブジェクトと Union Literal Types を使う
  ```ts
  // Good
  const Status = { Active: "active", Inactive: "inactive" } as const;
  type Status = (typeof Status)[keyof typeof Status];

  // Bad
  enum Status { Active = "active", Inactive = "inactive" }
  ```
- `interface` ではなく `type` を優先（拡張が必要な場合のみ `interface`）
- `Readonly<T>` / `ReadonlyArray<T>` で immutable を示す

## Null / Undefined

- Optional は `T | undefined` ではなく `T?` を使う（プロパティの場合）
- Nullable な値は早期 return か Optional Chaining（`?.`）で処理
- Non-null assertion（`!`）は禁止。代わりに型ガードかエラー throw を行う

## エラーハンドリング

- `try/catch` の `catch (e)` は `catch (e: unknown)` として扱う
- カスタムエラーは `Error` を継承し、`name` プロパティを設定する

## Import / Export

- default export より named export を優先
- import は `@/...` のパスエイリアスを使う
- 型のみの import は `import type { ... }` を使う

## 命名

- 変数・関数: `camelCase`
- 型・クラス・interface: `PascalCase`
- 定数（モジュール外で使う設定値）: `SCREAMING_SNAKE_CASE`
- ファイル名: `kebab-case.ts`、テストは `<name>.test.ts`

## 禁止事項

- `// @ts-ignore` / `// @ts-expect-error` をコメントなしで使う
- `Function` 型の使用（具体的なシグネチャを書く）
- 暗黙的な `any` を許容する設定変更
