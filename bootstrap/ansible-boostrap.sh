#!/bin/bash
set -euo pipefail

BOOTSTRAP_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P )"
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. >/dev/null 2>&1 && pwd -P )"
log() { echo -e "\e[92m[OK]\e[39m $@"; }
err() { echo -e "\e[91m[ERR]\e[39m $@" >&2; }

# no su check
[[ $(id -u) -eq 0 ]] && err "This script must _NOT_ be run with super-user privileges." && exit 3

# parse args
DEPLOY_TARGET=""
USER="docanimopi"
ASK_PASS=""
REBOOT="n"
ROLE=""
PORT="22"
OPTIONS=t:,u:,r:,p:
LONGOPTS=target:,user:,ask,reboot,role:,port:
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "Theres an error with your arguments..." >&2; exit 2
fi
eval set -- "$PARSED"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ask)         ASK_PASS="--ask-pass --ask-become-pass" ;;
        -u|--user)     USER="$2"; shift ;;
        -t|--target)   DEPLOY_TARGET="$2"; shift ;;
        -r|--role)     ROLE="$2"; shift ;;
        -p|--port)     PORT="$2"; shift ;;
        --reboot)      REBOOT="y" ;;
        --) shift; break ;;
        *) break ;;
    esac
    shift
done
[ -z "$DEPLOY_TARGET" ] && [ "$#" -ge 1 ] && DEPLOY_TARGET="$1" && shift
[ -z "$DEPLOY_TARGET" ] && err "Missing deploy target" && exit 1

cd $BOOTSTRAP_ROOT/ansible
if [ ! -d roles_galaxy ]; then
    log "Downloading ansible galaxy roles"
    ansible-galaxy install -r requirements.yml
    cp requirements.yml roles_galaxy/requirements.yml
fi
if ! `diff requirements.yml roles_galaxy/requirements.yml 1>/dev/null`; then
    log "requirements.yml changed. Fetching ansible galaxy roles"
    ansible-galaxy install -r requirements.yml
    cp requirements.yml roles_galaxy/requirements.yml
fi
if [ -n "$ROLE" ]; then
    log "Running ansible role $ROLE"
    ANSIBLE_HOST_KEY_CHECKING=false $BOOTSTRAP_ROOT/ansible/scripts/with-mitogen.sh \
        ansible-playbook \
            -i $DEPLOY_TARGET, \
            --user $USER \
            $ASK_PASS \
            -e "MY_ROLE=$ROLE" \
            -e "ansible_port=${PORT}" \
            playbooks/role.yml
else
    log "Running ansible playbook bootstrap.yml"
    ANSIBLE_HOST_KEY_CHECKING=false $BOOTSTRAP_ROOT/ansible/scripts/with-mitogen.sh \
        ansible-playbook \
            -vv \
            -i $DEPLOY_TARGET, \
            --user $USER \
            $ASK_PASS \
            -e "ansible_port=${PORT}" \
            playbooks/bootstrap.yml
fi

if [ "$REBOOT" == "y" ]; then
    log "Rebooting $DEPLOY_TARGET"
    ssh "$USER@$DEPLOY_TARGET" 'ip -br a; sudo reboot'
fi