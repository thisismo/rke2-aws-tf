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
    sleep 10
  done

  wait $!

  nodereadypath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
  until kubectl get nodes --selector='node-role.kubernetes.io/master' -o jsonpath="$nodereadypath" | grep -E "Ready=True"; do
    info "$(timestamp) Waiting for servers to be ready..."
    sleep 10
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

set_node_ips() {
  export NODE_IP=$(hostname --all-ip-addresses | awk '{print $2}') #private hetzner network ipv4
  export NODE_EXTERNAL_IP=$(hostname --all-ip-addresses | awk '{print $1}') #public ipv4
  info "Got node ips: $${NODE_IP}(private) $${NODE_EXTERNAL_IP}(external)"
  append_config "node-ip: $${NODE_IP}"
  #append_config "node-external-ip: $${NODE_EXTERNAL_IP}"
}

configure_network() {
  modprobe br_netfilter
  cat <<EOF >>/etc/sysctl.conf

# Allow IP forwarding for kubernetes
net.ipv4.ip_forward = 1
EOF
  sysctl -p
}

{
  pre_userdata

  config
  set_token

  configure_network
  set_node_ips

  append_config 'kubelet-arg: "cloud-provider=external"'
  append_config 'resolv-conf: "/run/systemd/resolve/resolv.conf"'

  if [ "$TYPE" = "server" ]; then #server
    # Initialize server
    info "Initializing server..."

    if [ "$CCM" = "true" ]; then
      append_config 'disable-cloud-controller: "true"'
      append_config 'cni: "cilium"'
      #append_config "node-external-ip: $${NODE_EXTERNAL_IP}"
    fi

    #append_config 'kube-apiserver-arg: "kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP"'

    cat <<EOF >> "/etc/rancher/rke2/config.yaml"
tls-san:
  - ${server_url}
  - 10.0.0.2
EOF

    if [ "$SERVER_TYPE" = "server" ]; then     # additional server joining an existing cluster
      info "I am just a server. Humpf."
      append_config "server: https://10.0.0.2:9345"

      # Wait for cluster to exist, then init another server
      cp_wait
    fi

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

        # cilium config
        cat <<EOF | sudo tee /var/lib/rancher/rke2/server/manifests/cilium-config.yaml
${cilium_config}
EOF

        # ccm
        kubectl -n kube-system create secret generic hcloud --from-literal=token=${hcloud_token} --from-literal=network=${hcloud_network}
        cat <<EOF | sudo tee /var/lib/rancher/rke2/server/manifests/hcloud-ccm.yaml
${ccm_manifest}
EOF

        #kubectl -n kube-system patch ds rke2-cilium --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'

        # csi
        kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${hcloud_token}
        cat <<EOF | sudo tee /var/lib/rancher/rke2/server/manifests/hcloud-csi.yaml
${csi_manifest}
EOF
      fi
    fi

  else #agent
    info "Initializing agent..."
    append_config "server: https://10.0.0.2:9345"

    # Default to agent
    systemctl enable rke2-agent
    systemctl daemon-reload
    systemctl start rke2-agent
  fi

  post_userdata
}
