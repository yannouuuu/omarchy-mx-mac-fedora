if command -v ufw >/dev/null 2>&1; then
  # Allow nothing in, everything out.
  ufw default deny incoming || true
  ufw default allow outgoing || true

  # Allow ports for LocalSend.
  ufw allow 53317/udp || true
  ufw allow 53317/tcp || true

  # Allow Docker containers to use DNS on host.
  ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns' 2>/dev/null || true
  ufw allow in proto udp from 192.168.0.0/16 to 172.17.0.1 port 53 comment 'allow-docker-dns' 2>/dev/null || true

  if command -v ufw-docker >/dev/null 2>&1; then
    install_ufw_docker_rules() {
      local shim_dir status ufw_docker_bin
      ufw_docker_bin=$(command -v ufw-docker)
      shim_dir=$(mktemp -d)
      cat >"$shim_dir/ufw" <<'EOF'
#!/bin/bash
if [[ ${1:-} == "status" ]]; then
  echo "Status: active"
  exit 0
fi
exec /usr/bin/ufw "$@"
EOF
      sed "0,/^PATH=/s#^PATH=.*#PATH=\"$shim_dir:/bin:/usr/bin:/sbin:/usr/sbin:/snap/bin/\"#" \
        "$ufw_docker_bin" >"$shim_dir/ufw-docker"
      chmod 755 "$shim_dir/ufw" "$shim_dir/ufw-docker"

      if "$shim_dir/ufw-docker" install 2>/dev/null; then
        status=0
      else
        status=$?
      fi
      rm -rf "$shim_dir"
      return "$status"
    }
    install_ufw_docker_rules || true
  fi

  [[ -f /etc/ufw/ufw.conf ]] && sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf || true
  systemctl enable ufw 2>/dev/null || true
elif command -v firewall-cmd >/dev/null 2>&1; then
  systemctl enable firewalld 2>/dev/null || true
fi
