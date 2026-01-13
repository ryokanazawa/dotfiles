# login shell 用：bashrcを読むだけにする
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

# 共通設定
if [ -f "$HOME/.shellrc" ]; then
  . "$HOME/.shellrc"
fi
