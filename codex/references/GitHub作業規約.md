# GitHub作業規約

PR・Issue・GitHub Actionsの作業時に適用する共通規約。操作には対応するワークフローを使い、CLIはshim経由の `gh` を優先する。

PRの作成・レビュー・修正・マージ時だけ、追加で [PR作業規約](PR作業規約.md) を読む。

## 開始と権限

- GitHubのIssue・PRが提示されたら、最初に `git status -sb` を確認する。未コミット変更があれば変更前に報告する。URLの提示だけではpush・pullの許可にならない。
- `fix ci` はpull・commit・pushの許可を含む。`gh run list/view` で調べ、修正・再実行・監視を成功まで進める。

## 公開本文の送信

- GitHubの公開本文は一時ファイルへ `cat <<'EOF'` で書き、内容を確認して `--body-file` で渡す。バッククォート、`$`、シェル断片、環境変数名、ユーザーの文章を含む本文を、シェルの二重引用符へ直接埋め込まない。
- 秘密・環境変数の取り扱い後に公開の `gh` 書き込みを行う際は、可能なら `env -u GITHUB_TOKEN -u GH_TOKEN -u HOMEBREW_GITHUB_API_TOKEN ...` でトークン環境変数を外す。

## 完了

- Issueが `main` で修正済みと検証できたら、検証結果とcommit・PRへの参照をコメントし、Issueを閉じる。
- 最終報告は簡潔な文章で、挙動、主な変更箇所、検証結果、Issue・PRの状態を伝える。有用なリファクタや簡素化の候補があれば提案する。
