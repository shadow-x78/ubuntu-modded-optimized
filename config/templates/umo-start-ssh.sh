#!/bin/sh
# UMO — Start SSH (template)
echo "[==>] Starting SSH server..."

[ -d /run/sshd ] || mkdir -p /run/sshd

[ -f /etc/ssh/ssh_host_rsa_key ] || ssh-keygen -A 2>/dev/null || true

/usr/sbin/sshd -D "$@"
