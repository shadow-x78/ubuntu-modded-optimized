#!/bin/sh
# UMO — Start SSH (template)
echo "[==>] Starting SSH server..."

# Create /run/sshd if missing
[ -d /run/sshd ] || mkdir -p /run/sshd

# Generate host keys if missing
[ -f /etc/ssh/ssh_host_rsa_key ] || ssh-keygen -A 2>/dev/null || true

# Start sshd
/usr/sbin/sshd -D "$@"