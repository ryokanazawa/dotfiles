# worktree統合

`git worktree list --porcelain`で`refs/heads/main`のチェックアウト先を特定する。現在地がmainでなければ、コミット直後に次を行う。

mainチェックアウトが存在しない場合は、新しいworktreeやブランチを作らず、現在のコミットSHAを報告して停止する。

1. mainチェックアウトで`git status --short --branch`を確認する。remoteがありmainが遅れていれば`git pull --ff-only`でローカルmainを最新化する（remoteが無い、または失敗した場合はローカルmainのままで進める）。
2. 作業worktree（detached HEADを含む）で`git rebase main`を実行する。コンフリクトしたら範囲内で解消し、関連検証とautoreviewを行ってから`git rebase --continue`する。解消できなければ`git rebase --abort`で戻して停止する。rebase後の各コミットSHAを記録し直す。
3. mainの未コミット変更パスと今回のコミット群の変更パスを比較する。重なる場合は[未コミット変更の退避](未コミット変更の退避.md)へ。
4. パスが重ならなければ、mainチェックアウト側で`git merge --ff-only <rebase後の先端コミットSHA>`を実行する。mainの未コミット変更は保持したまま行う。
5. `--ff-only`が失敗したらまずrebase不足を疑い、ステップ2へ戻って`git rebase main`からやり直す。それでも拒否されるなら原因を調べ、未コミット変更が阻害している場合は[未コミット変更の退避](未コミット変更の退避.md)へ。`--no-ff`や通常の`git merge`は絶対に使わない。
6. `git merge-base --is-ancestor <rebase後の各コミットSHA> main`で反映を確認する。

mainがdirtyという理由だけでは停止しない。統合後は呼び出し元のpush・同期確認へ戻る。統合対象がレビュー時点から変わっていれば、マージ前にautoreviewで最新の対象を確認する。
