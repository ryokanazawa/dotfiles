---
name: prd-to-issues
description: 要件定義書を、各層を貫いて単独で検証できる作業項目に分割し、ローカルのMarkdown文書にまとめる。要件のタスク分割や実装作業の整理を依頼されたときに使う。
---

# 要件定義書から作業項目への分割

要件定義書を、各層を貫く小さな機能単位で作業項目に分割する。成果物は日本語のローカルMarkdown文書とし、GitHub Issue・PRは作成しない。

## Process

### 1. Locate the PRD

会話内の要件定義書、ユーザー指定のローカル文書、リポジトリの既存文書を確認する。対象が特定できない場合は、文書のパスまたは本文をユーザーに尋ねる。

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code.

### 3. Draft vertical slices

要件定義書を、すべての統合層を端から端まで貫く小さな作業項目に分割する。単一の層だけを実装する分割にはしない。

Slices may be 'HITL' or 'AFK'. HITL slices require human interaction, such as an architectural decision or a design review. AFK slices can be implemented and merged without human interaction. Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories from the PRD this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?

Iterate until the user approves the breakdown.

### 5. 作業項目をローカル文書に保存する

承認された分割案を、以下のテンプレートで「作業項目.md」などの日本語名のMarkdown文書に保存する。配置はリポジトリの既存の文書配置に合わせ、無関係な文書は上書きしない。

各項目に「作業 1」のような一意で安定した番号を付け、依存先をその番号で参照する。既存の番号は変更せず、新規項目は依存先が先になる順に並べる。テンプレートの見出しも日本語にする。完了時に保存した文書へのリンクを示す。

<work-item-template>
## Parent PRD

元の要件定義書への相対Markdownリンク。会話内にのみ存在する場合は、参照元の要件を特定できる短い説明。

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation. Reference specific sections of the parent PRD rather than duplicating content.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- 作業 1（依存する作業番号）

依存先がなければ「なし（すぐに着手可能）」と記載する。

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 7

</work-item-template>

元の要件定義書は変更しない。
