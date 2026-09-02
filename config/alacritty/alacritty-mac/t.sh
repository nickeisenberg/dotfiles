rm ~/Applications/Alacritty.app/Contents/MacOS/alacritty

cat > ~/Applications/Alacritty.app/Contents/MacOS/alacritty <<'EOF'
#!/bin/bash

exec /Users/eisenbnt/.local/src/miniconda3/bin/alacritty \
    --config-file /Users/eisenbnt/.config/alacritty/alacritty.toml
EOF

chmod +x ~/Applications/Alacritty.app/Contents/MacOS/alacritty
