---
name: review-since-last
description: 最後にレビュー済みのGitコミットからHEADまでを、各コミットと結合差分の両方で再レビューする。ユーザーが前回以降、未レビュー範囲、朝のコード確認、last-reviewed..HEADのレビューを求めたときに使う。
---

# 前回以降のレビュー

ローカル参照`refs/review-since-last/last-reviewed`を基準点にする。レビューは読み取り専用で行い、完了時だけ基準点を進める。

## 手順

1. `scripts/review_range.sh inspect --repo <repository>`を実行する。
   - 終了コード3なら基準点未設定。履歴を読み、どのcommit以前をレビュー済みとして始めるかユーザーへ確認する。黙って初期化しない。
   - `COUNT=0`なら未レビューcommitなしと報告して終了する。
2. `git status --short`を確認する。未コミット差分は今回の範囲外として明示し、混ぜて評価しない。
3. `COMMIT`を古い順に一件ずつレビューする。
   - `git show --find-renames --stat <commit>`で目的と範囲を把握する。
   - `git show --find-renames --format=fuller <commit>`と関連ファイルを読み、正しさ、回帰、失敗経路、テスト不足、保守性を確認する。
   - 後続commitで直っていても、その事実を記録してから次へ進む。
4. `git diff --find-renames <RANGE>`をレビューし、commit間の相互作用、重複、取り残しを確認する。
5. プロジェクト指示に従い、範囲に対応する高速な検証を実行する。失敗はfindingとして扱う。
6. findingを重大度順に、ファイルと行を添えて報告する。findingがなければその旨、確認したcommit数、実行した検証を報告する。
7. 未解決findingがなく、列挙時の`HEAD`までレビューし終えた場合だけ、`scripts/review_range.sh mark --repo <repository> <HEAD>`を実行する。
   - findingがある場合は基準点を進めない。
   - 修正commitが追加された場合は、同じ`BASE`から新しいHEADまで結合差分を再確認してからmarkする。

## レビュー規則

- スタイルの好みより、実際に壊れる挙動と保守上の具体的な危険を優先する。
- commit単体と結合差分の両方を省略しない。
- レビューしていないcommitを含む位置へ基準点を進めない。
- 履歴を書き換えない。修正は新しいcommitとして扱う。
