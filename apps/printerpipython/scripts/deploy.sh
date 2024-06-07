#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../../.. >/dev/null 2>&1 && pwd -P )"
BUILD_ROOT="$PROJECT_ROOT/apps/printerpi/build"

log() { echo -e "\e[92m[OK]\e[39m $@"; }
err() { echo -e "\e[91m[ERR]\e[39m $@" >&2; }

# parse args
DEPLOY_TARGET=""
USER="docanimopi"
SKIP_DEPS=""
PORT=22
OPTIONS=t:,u:,s,p:
LONGOPTS=target:,user,skip:,port:
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "Theres an error with your arguments..." >&2; exit 2
fi
eval set -- "$PARSED"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--user)     USER="$2"; shift ;;
        -t|--target)   DEPLOY_TARGET="$2"; shift ;;
        -p|--port)   PORT="$2"; shift ;;
        -s|--skip)  SKIP_DEPS="--no-deps"; shift ;;
        --) shift; break ;;
        *) break ;;
    esac
    shift
done
[ -z "$DEPLOY_TARGET" ] && [ "$#" -ge 1 ] && DEPLOY_TARGET="$1" && shift
[ -z "$DEPLOY_TARGET" ] && echo "Missing deploy target" && exit 1

rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT"
cd "$PROJECT_ROOT/apps/printerpipython"
python3 setup.py bdist_wheel -d "$BUILD_ROOT"

log "Deploying apps"
rsync -avh --delete --rsh="ssh -p ${PORT}" "$BUILD_ROOT"/ "$USER@$DEPLOY_TARGET":"/tmp/pythonapps/"


APPS="
"

ssh "$USER@$DEPLOY_TARGET" -p "${PORT}" \
    "bash -c '
        set -euo pipefail
        set -x
        sudo pip3 install --ignore-installed --break-system-packages $SKIP_DEPS '/tmp/pythonapps/*.whl '
        for APP in `echo $APPS`; do
            if \` systemctl is-active \$APP >/dev/null \`; then
                sudo systemctl restart \$APP
            fi
        done
    '"