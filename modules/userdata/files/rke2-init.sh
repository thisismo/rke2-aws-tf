#!/bin/sh

export TYPE="${type}" #server or agent
export CCM="${ccm}"
export SERVER_TYPE="${server_type}" #leader or server

# info logs the given argument at info log level.
info() {
    echo "[INFO] " "$@"
}

# warn logs the given argument at warn log level.
warn() {
    echo "[WARN] " "$@" >&2
}

# fatal logs the given argument at fatal log level.
fatal() {
    echo "[ERROR] " "$@" >&2
    exit 1
}

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

config() {
  mkdir -p "/etc/rancher/rke2"
  cat <<EOF > "/etc/rancher/rke2/config.yaml"
# Additional user defined configuration
${config}
EOF
}

append_config() {
  echo "$1" >> "/etc/rancher/rke2/config.yaml"
}

cp_wait() {
  while true; do
    supervisor_status=$(curl --write-out '%%{http_code}' -sk --output /dev/null https://${server_url}:9345/ping)
    if [ "$supervisor_status" -eq 200 ]; then
      info "Cluster is ready"

      # Let things settle down for a bit, not required
      # TODO: Remove this after some testing
      sleep 10
      break
    fi
    info "Waiting for cluster to be ready..."
    sleep 10
  done
}

local_cp_api_wait() {
  export PATH=$PATH:/var/lib/rancher/rke2/bin
  export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

  while true; do
    info "$(timestamp) Waiting for kube-apiserver..."
    if timeout 1 bash -c "true <>/dev/tcp/localhost/6443" 2>/dev/null; then
        break
    fi
    sleep 5
  done

  wait $!

  nodereadypath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
  until kubectl get nodes --selector='node-role.kubernetes.io/master' -o jsonpath="$nodereadypath" | grep -E "Ready=True"; do
    info "$(timestamp) Waiting for servers to be ready..."
    sleep 5
  done

  info "$(timestamp) all kube-system deployments are ready!"
}

set_token() {
  info "Setting rke2 join token... (${token})"
  echo "token: ${token}" >> "/etc/rancher/rke2/config.yaml"
}

pre_userdata() {
  info "Beginning user defined pre userdata"
  ${pre_userdata}
  info "Ending user defined pre userdata"
}

post_userdata() {
  info "Beginning user defined post userdata"
  ${post_userdata}
  info "Ending user defined post userdata"
}

configure_network() {
  info "Configuring network"
  modprobe br_netfilter
  cat <<EOF >>/etc/sysctl.conf

# Allow IP forwarding for kubernetes
net.ipv4.ip_forward = 1
net.ipv6.conf.default.forwarding = 1
EOF
  sysctl -p
}

{
  pre_userdata

  config
  set_token

  configure_network


  if [ "$CCM" = "true" ]; then
    #append_config 'kubelet-arg: "cloud-provider=external"'
    append_config 'disable-cloud-controller: "true"'
    #append_config 'cloud-provider-name: "hcloud"'
  fi

  if [ "$TYPE" = "server" ]; then #server
    # Initialize server
    info "Initializing server..."

    cat <<EOF >> "/etc/rancher/rke2/config.yaml"
tls-san:
  - ${server_url}
EOF

    if [ "$SERVER_TYPE" = "server" ]; then     # additional server joining an existing cluster
      info "I am just a server. Humpf."
      append_config "server: https://${server_url}:9345"

      # Wait for cluster to exist, then init another server
      cp_wait
    fi

    append_config "node-ip: 10.0.0.4"

    systemctl enable rke2-server
    systemctl daemon-reload
    systemctl start rke2-server

    info "Started server service"

    export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    export PATH=$PATH:/var/lib/rancher/rke2/bin

    if [ "$SERVER_TYPE" = "leader" ]; then
      # For servers, wait for apiserver to be ready before continuing so that `post_userdata` can operate on the cluster
      info "I am leader. Yey."

      local_cp_api_wait

      # Initialize Cloud Controller Manager
      if [ "$CCM" = "true" ]; then
        info "Deploying Cloud-Controller-Manager"
        # manifestos addons
        while ! test -d /var/lib/rancher/rke2/server/manifests; do
            info "Waiting for '/var/lib/rancher/rke2/server/manifests'"
            sleep 5
        done

        # ccm
        kubectl -n kube-system create secret generic hcloud --from-literal=token=${hcloud_token} --from-literal=network=${hcloud_network}
        cat <<EOF | sudo tee /var/lib/rancher/rke2/server/manifests/hcloud-ccm.yaml
${ccm_manifest}
EOF

        # csi
        kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${hcloud_token}
        cat <<EOF | sudo tee /var/lib/rancher/rke2/server/manifests/hcloud-csi.yaml
${csi_manifest}
EOF

        # canal config to use hcloud network interface for intra-cluster communication
        cat <<EOF | sudo tee /var/lib/rancher/rke2/server/manifests/canal-config.yaml
${canal_config}
EOF
      fi
    fi

  else #agent
    info "Initializing agent..."
    if [ "$CCM" = "true" ]; then
      append_config 'kubelet-arg: "cloud-provider=external"'
      append_config 'node-ip: 10.0.0.3'
    fi
    append_config "server: https://${server_url}:9345"

    # Default to agent
    systemctl enable rke2-agent
    systemctl daemon-reload
    systemctl start rke2-agent
  fi

  post_userdata
}
