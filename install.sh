#!/usr/bin/env bash
set -euo pipefail

echo "[1] Download Neovim v0.11.3"
curl -fsSLO https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

echo "[2] Dev packages (without neovim/nodejs from apt)"
sudo apt install -y --no-install-recommends git build-essential unzip curl xclip ripgrep fd-find fontconfig fonts-noto-color-emoji make gcc zsh

echo "[3] Remove conflicting packages"
sudo apt remove -y vim vim-tiny vi neovim nodejs libnode-dev libnode109 || true
sudo apt autoremove -y || true

echo "[4] Symlinks for nvim and fd"
sudo ln -sf /usr/local/bin/nvim /usr/bin/vi
sudo ln -sf /usr/local/bin/nvim /usr/bin/vim
sudo ln -sf /usr/local/bin/nvim /usr/local/bin/vi
sudo ln -sf /usr/local/bin/nvim /usr/local/bin/vim
command -v fd >/dev/null || sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd

echo "[5] Configure update-alternatives for vi/vim"
sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/nvim 100
sudo update-alternatives --install /usr/bin/vim vim /usr/local/bin/nvim 100
sudo update-alternatives --set vi /usr/local/bin/nvim
sudo update-alternatives --set vim /usr/local/bin/nvim

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

echo "[6] Go v1.25.0"
GO_VERSION=1.25.0

sudo apt remove -y golang golang-go golang-1.* || true
sudo apt autoremove -y || true

sudo rm -rf /usr/local/go
curl -fsSLO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"

for rcfile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  if [ -f "$rcfile" ]; then
    if ! grep -q '/usr/local/go/bin' "$rcfile" 2>/dev/null; then
      echo 'export PATH=$PATH:/usr/local/go/bin' >> "$rcfile"
    fi
  fi
done

export PATH="$PATH:/usr/local/go/bin"

if ! command -v go >/dev/null 2>&1; then
  echo "ERROR: Go installation failed"
  exit 1
fi
echo "Go installed: $(go version)"

echo "[7] nvm + Node LTS"
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rcfile" ]; then
    if ! grep -q 'NVM_DIR' "$rcfile" 2>/dev/null; then
      cat >> "$rcfile" << 'NVMEOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
NVMEOF
    fi
  fi
done

# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"
nvm install --lts
corepack enable || true
npm install -g typescript

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: Node installation failed"
  exit 1
fi
echo "Node installed: $(node --version)"
echo "npm installed: $(npm --version)"

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
echo "Verifying installations:"
for b in nvim vi vim rg fd git go node npm dotnet python3; do
  if command -v "$b" >/dev/null 2>&1; then
    case "$b" in
      nvim|go|node|npm|dotnet|python3)
        version=$($b --version 2>&1 | head -1 || true)
        ;;
      *)
        version="OK"
        ;;
    esac
    printf '  %-10s: %s (%s)\n' "$b" "$(command -v "$b")" "$version"
  else
    printf '  %-10s: MISSING\n' "$b"
  fi
done

echo "[11] Clone config"
[ -d "$HOME/.config/nvim" ] || git clone https://github.com/thefnordling/kickstart.nvim.git "$HOME/.config/nvim"

echo "Done! Installation complete."
echo ""
echo "Next steps:"
echo "  1. Set terminal font to 'MesloLGS NF'"
echo "  2. Restart your shell or run: source ~/.bashrc  (or ~/.zshrc)"
echo "  3. Run: nvim"
echo ""
