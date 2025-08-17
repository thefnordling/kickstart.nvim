#!/usr/bin/env bash
set -euo pipefail

echo "[1] Apt base"
sudo apt update
sudo apt install -y software-properties-common

echo "[2] Neovim PPA"
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt update

echo "[3] Remove old vi/vim"
sudo apt remove -y vim vim-tiny vi || true

echo "[4] Dev packages"
sudo apt install -y git build-essential unzip curl xclip ripgrep fd-find fontconfig fonts-noto-color-emoji neovim make gcc

echo "[5] Symlinks"
sudo ln -sf /usr/bin/nvim /usr/bin/vi
sudo ln -sf /usr/bin/nvim /usr/bin/vim
command -v fd >/dev/null || sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd

echo "[6] Meslo font"
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

echo "[7] Go"
GO_VERSION=1.25.0
curl -fsSLO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"
if ! grep -q '/usr/local/go/bin' "$HOME/.profile"; then
  echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
fi
export PATH="$PATH:/usr/local/go/bin"

echo "[8] nvm + Node LTS"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"
nvm install --lts
corepack enable || true
npm install -g typescript

echo "[9] .NET 8"
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
sudo tee /etc/apt/sources.list.d/microsoft-prod.list >/dev/null <<'EOF'
deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main
EOF
sudo apt update
sudo apt install -y dotnet-sdk-8.0

echo "[10] Python 3"
sudo apt install -y python3 python3-pip python3-venv

echo "[11] Go delve"
go install github.com/go-delve/delve/cmd/dlv@latest

echo "[12] Verify tools"
for b in nvim rg fd git go node npm dlv dotnet python3; do
  printf '%-7s: %s\n' "$b" "$(command -v "$b" || echo MISSING)"
done

echo "[13] Clone config"
[ -d "$HOME/.config/nvim" ] || git clone https://github.com/thefnordling/kickstart.nvim.git "$HOME/.config/nvim"

echo "Done. Set terminal font to MesloLGS NF then run: nvim"
