#!/bin/sh
# Copia la config actual de ~/.config al repo (config/) y hace commit.
# Uso: ./snap.sh "mensaje"
cd "$(dirname "$0")" || exit 1
for p in hypr waybar rofi swayosd kitty cosmic-shell; do
  mkdir -p "config/$p"
  rsync -a --delete \
    --exclude='*.bak*' --exclude='*.backup*' --exclude='*.before*' --exclude='*.test' \
    --exclude='__pycache__' --exclude='lock-bg.png' --exclude='lock-avatar.png' \
    --exclude='wallpaper.mp4' --exclude='wallpaper.webm' --exclude='wallpaper.png' --exclude='wallpaper.jpg' \
    --exclude='cfg/local.lua' --exclude='modules/' \
    "$HOME/.config/$p/" "config/$p/"
done
git add -A
git commit -qm "${1:-snapshot}" && git log --oneline | head -1
