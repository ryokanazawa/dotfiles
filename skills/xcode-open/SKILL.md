---
name: xcode-open
description: 今いるgit worktreeのXcodeプロジェクトをXcode.appで開く。worktreeで作業中ならそのworktree側のプロジェクトを開く。Xcodeで開いて、プロジェクトを開いて、Xcode立ち上げて、と依頼されたときに使う。ビルドや実行はしない。
---

# xcode-open — 今いる worktree のプロジェクトを Xcode で開く

`scripts/open-project.sh`（このスキルの基準ディレクトリ配下）が、コンテナ判定から起動までを1コマンドでやる。エージェントは実行して出力を報告するだけ。

- **cwd の worktree を開く。** `git rev-parse --show-toplevel` が現在の worktree のルートを返すので、worktree 判定の特別扱いは要らない。書き足さないこと。
- **開くだけ。** ビルドも実行もしない。ビルドしてシミュレータで動かすなら `xcode-build` スキル（あちらは逆に Xcode.app を起動しない）。

## 手順

1. 実行する。

```sh
# 先頭は展開時に提示される「Base directory for this skill」の値
/Users/ryo/.claude/skills/xcode-open/scripts/open-project.sh
```

2. 出力の4行（`worktree:` / `branch:` / `opened:` / `xcode:`）を**そのまま報告する**。Xcode は複数 worktree の同名プロジェクトを同時に開けてしまい、ウィンドウを見ても見分けがつかない。どのコピーをどの Xcode で開いたかは、この出力でしか確認できない。

## 選び方

ルート直下だけを見て、`.xcworkspace` > `.xcodeproj` > `Package.swift` の順に選ぶ。workspace があるのに project を開くと SPM / CocoaPods の依存が解決されないため、この順序は崩さない。

サブディレクトリにプロジェクトがある構成では見つからず `error:` で止まる。そのときはパスを確認して `open -a Xcode <パス>` する。**スクリプトの探索を深くしない**（`Foo.xcodeproj/project.xcworkspace` や `.claude/worktrees/*/Foo.xcodeproj` を拾って別 worktree を開く）。

## 完了条件

- スクリプトが終了コード 0 を返し、`worktree:` / `branch:` / `opened:` / `xcode:` を報告している。
- 開いたのが cwd の worktree のプロジェクトである。
