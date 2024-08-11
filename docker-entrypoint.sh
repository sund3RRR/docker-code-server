#!/bin/bash

copy_file() {
    local src=$1
    local dest=$2
    local owner="coder:coder"
    local dest_dir=$(dirname "$dest")

    if [ ! -d "$dest_dir" ]; then
        echo "-----| Directory $dest_dir is missing. Creating... |-----"
        gosu coder bash -c "mkdir -p '${dest_dir}'"
    fi

    if [ ! -f "$dest" ]; then
        echo "-----| File $dest is missing. Copying from $src. |-----"
        cp "$src" "$dest"
        chown "$owner" "$dest"
    fi
}


echo "-----| Setting User Parameters |-----"
export USER="coder"
export HOME="/home/$USER"

PUID=${PUID:-911}
PGID=${PGID:-911}

groupmod -o -g "$PGID" "$USER"
usermod -o -u "$PUID" "$USER"

echo "
GID/UID
───────────────────────────────────────
User UID:    $(id -u coder)
User GID:    $(id -g coder)
───────────────────────────────────────
"


echo "-----| Setting Timezone |-----"
TZ=${TZ:-"Europe/London"}
ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime

echo "
Timezone
───────────────────────────────────────
TZ: $TZ
───────────────────────────────────────
"


NIX_DIR=/home/coder/.nix-profile
if [ ! -f "$NIX_DIR/bin/nix-env" ] || ! "$NIX_DIR/bin/nix-env" --version > /dev/null 2>&1; then
    echo "-----| Installing Nix Package Manager |----"
    gosu coder bash -c "curl -L https://nixos.org/nix/install | sh -s -- --no-daemon"
fi

echo "
Nix Package Manager
───────────────────────────────────────
$($NIX_DIR/bin/nix-env --version)
───────────────────────────────────────
"


echo "-----| Configuring Home Directory |-----"
copy_file "/app/home-template/.bashrc" "$HOME/.bashrc"
copy_file "/app/home-template/.profile" "$HOME/.profile"
copy_file "/app/home-template/.config/home-manager/home.nix" "$HOME/.config/home-manager/home.nix"


if grep -q "@version@" "$HOME/.config/home-manager/home.nix"; then
    echo "-----| Setting up home-manager |-----"
    gosu coder bash -c "${NIX_DIR}/bin/nix-env -iA nixpkgs.home-manager"
    version=$("${NIX_DIR}/bin/home-manager" --version)
    version=$(echo "$version" | sed 's/-pre$//')
    sed -i "s/@version@/$version/" "$HOME/.config/home-manager/home.nix"
    gosu coder bash -c "PATH='$NIX_DIR/bin:$PATH' ${NIX_DIR}/bin/home-manager switch"
fi


echo "-----| Starting code-server |-----"
if [ -n "${PASSWORD}" ]; then
    AUTH="password"
else
    AUTH="none"
fi

PORT=${PORT:-8080}

echo "
code-server
───────────────────────────────────────
Auth type: $AUTH
Port:      $PORT
Workspace: $HOME/Workspace
───────────────────────────────────────
"

exec gosu coder /app/code-server/bin/code-server \
    --bind-addr "0.0.0.0:${PORT}" \
    --user-data-dir "$HOME/data" \
    --extensions-dir "$HOME/extensions" \
    --disable-telemetry \
    --auth "${AUTH}" \
    "${HOME}/Workspace"
