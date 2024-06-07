#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../../.. >/dev/null 2>&1 && pwd -P )"
ANSIBLE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. >/dev/null 2>&1 && pwd -P )"

log() { echo -e "\e[92m[OK]\e[39m $@"; }
err() { echo -e "\e[91m[ERR]\e[39m $@" >&2; }

[ ! -d "$ANSIBLE_ROOT/venv" ] \
    && log "Missing venv. Creating..." \
    && python3 -m venv "$ANSIBLE_ROOT/venv"

source "$ANSIBLE_ROOT/venv/bin/activate"

if ! pip3 show ansible > /dev/null; then
    pip3 install ansible~=2.9.0
fi

if [ ! -e "$ANSIBLE_ROOT/venv/mitogen" ]; then
    wget -nv https://github.com/mitogen-hq/mitogen/archive/refs/heads/0.2-release.tar.gz -O - | tar -zx -C "$ANSIBLE_ROOT/venv/"
    mv "$ANSIBLE_ROOT/venv/mitogen-0.2-release" "$ANSIBLE_ROOT/venv/mitogen"
fi

exec "$@"