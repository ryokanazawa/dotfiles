# Dotfiles

個人マシンのシェル・エディタ・エージェント設定を一つのリポジトリで管理し、同じ導出・同じリンク規約で再現する。

## Language

**Project label**:
作業ディレクトリを端末タブやセッション名に出すときの短い表示名。git トップレベルディレクトリ名、リポジトリ外なら cwd のベース名。
_Avoid_: project name, repo name, cwd basename（呼び分けずこの語に統一）

**Session title**:
Claude の会話一覧に出す見出し。通常は「プロンプト断片 · project label」。
_Avoid_: window title（端末 OSC 側）, tab name

**Window title**:
端末（OSC 2）に出す文字列。zsh の precmd/preexec と Claude hook の terminalSequence が共有する面。
_Avoid_: session title と混同しない

**Link install**:
`dotfilesLink.sh` がリポジトリ内ファイルをホーム配下の期待パスへシンボリックリンクする手続き。skills は Claude・Codex・agents の三方へ張る。
_Avoid_: copy, sync（コピー運用ではない）

**Agent proxy**:
Claude Code と Anthropic API のあいだに置き、リクエストを監査用 Markdown に落とすローカル HTTP プロキシ（`proxy.mjs`）。
_Avoid_: logger, middleware
