#!/usr/bin/env bash
mkdir -p "$HOME/Pictures/Screenshots"
grim -g "$(slurp)" "$HOME/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png"
