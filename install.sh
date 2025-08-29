#!/usr/bin/env bash
set -euo pipefail

echo "[1] Download Neovim v0.11.3"
curl -fsSLO https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

echo "[2] Remove old vi/vim"
sudo apt remove -y vim vim-tiny vi || true

echo "[3] Dev packages"
sudo apt install -y git build-essential unzip curl xclip ripgrep fd-find fontconfig fonts-noto-color-emoji neovim make gcc python3 zsh

wget -q -O- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.zshrc || cat >> ~/.zshrc <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
EOF
grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
source ~/.bashrc
nvm install node

echo "[4] Symlinks"
sudo ln -sf /usr/bin/nvim /usr/bin/vi
sudo ln -sf /usr/bin/nvim /usr/bin/vim
command -v fd >/dev/null || sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd

echo "[5] Meslo font"
tmpdir="$(mktemp -d)"
(
  cd "$tmpdir"
  curl -fsSLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
  unzip -q Meslo.zip -d Meslo
  mkdir -p "$HOME/.local/share/fonts"
  cp Meslo/*.ttf "$HOME/.local/share/fonts/"
)
fc-cache -f
rm -rf "$tmpdir"

echo "[6] Go"
GO_VERSION=1.25.0
curl -fsSLO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"
if ! grep -q '/usr/local/go/bin' "$HOME/.profile"; then
  echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
fi
export PATH="$PATH:/usr/local/go/bin"

echo "[7] nvm + Node LTS"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"
nvm install --lts
corepack enable || true
npm install -g typescript

echo "[8] .NET 8"
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
sudo tee /etc/apt/sources.list.d/microsoft-prod.list >/dev/null <<'EOF'
deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main
EOF
sudo apt update
sudo apt install -y dotnet-sdk-8.0

echo "[9] Python 3"
sudo apt install -y python3 python3-pip python3-venv

echo "[10] Verify tools"
for b in nvim rg fd git go node npm dotnet python3; do
  printf '%-7s: %s\n' "$b" "$(command -v "$b" || echo MISSING)"
done

echo "[11] Clone config"
[ -d "$HOME/.config/nvim" ] || git clone https://github.com/thefnordling/kickstart.nvim.git "$HOME/.config/nvim"

echo "Done. Set terminal font to MesloLGS NF then run: nvim"
