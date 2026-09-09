#!/bin/sh
# Hamburger Server - enable remote access for Ani on a TEST machine.
# Project 40552501. Safe to run twice: it will not add the key again.
#
# What this does, in full - nothing hidden:
#   1. installs the standard OpenSSH server
#   2. adds ONE public key (Ani's) to this user's authorised keys
#   3. sets the correct permissions and starts the service
# It removes nothing, changes no passwords, and adds no other user.
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this with sudo." >&2
  exit 1
fi

U="${SUDO_USER:-lake001}"
H="$(getent passwd "$U" | cut -d: -f6)"
if [ -z "$H" ] || [ ! -d "$H" ]; then
  echo "Cannot find the home folder for user '$U' - stopping, nothing changed." >&2
  exit 1
fi

K='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIIZGyYaejNHMWFElvp8qEUBeZMU27Q+l4Gu0ywCoTJ ani-freelancer-40552501'

echo "Installing the remote access service ..."
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssh-server

mkdir -p "$H/.ssh"
chmod 700 "$H/.ssh"
touch "$H/.ssh/authorized_keys"

if grep -qF 'ani-freelancer-40552501' "$H/.ssh/authorized_keys"; then
  echo "The key was already there - not adding it twice."
else
  printf '%s\n' "$K" >> "$H/.ssh/authorized_keys"
  echo "Key added."
fi

chmod 600 "$H/.ssh/authorized_keys"
chown -R "$U":"$U" "$H/.ssh"

systemctl enable --now ssh >/dev/null 2>&1 || systemctl enable --now sshd >/dev/null 2>&1

if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
  echo ""
  echo "DONE - this machine now accepts Ani's key for user $U"
else
  echo ""
  echo "PROBLEM - the service did not start. Nothing else was changed."
  exit 1
fi
