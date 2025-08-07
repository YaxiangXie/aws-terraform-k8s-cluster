#!/bin/bash

######## For Master Node ########
hostname k8s-node${worker_number}
echo k8s-node${worker_number} > /etc/hostname
hostnamectl set-hostname k8s-node${worker_number}


export AWS_ACCESS_KEY_ID=${access_key}
export AWS_SECRET_ACCESS_KEY=${private_key}
export AWS_DEFAULT_REGION=${region}

apt-get update -y
sudo resize2fs /dev/nvme0n1p1
timedatectl set-timezone Asia/Taipei

# 關閉 swap
swapoff -a  
sed -ri 's/.*swap.*/#&/' /etc/fstab

# 設定 Host (使用私有的IP ， 先不做設定)

# 下載憑證、金鑰
apt-get install apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common -y
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg  
#echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#apt-get update

# 安裝 containerd
#apt-get install docker-ce docker-ce-cli containerd.io -y
mkdir -p /etc/containerd
apt-get install -y containerd

containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's#sandbox_image = ".*"#sandbox_image = "registry.k8s.io/pause:3.9"#' /etc/containerd/config.toml
sed -i "/registry\.mirrors]/a [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"203.64.95.35:8853\"]\n  endpoint = [\"http://203.64.95.35:8853\"]" /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

apt install awscli -y  


# 安裝 Kubernetes
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" >> ~/kubernetes.list
mv ~/kubernetes.list /etc/apt/sources.list.d
apt update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni

# 把kube proxy使⽤ipvs或iptables代理
modprobe br_netfilter
# lsmod | grep br_netfilter
# sysctl net.bridge.bridge-nf-call-iptables=1
tee /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
overlay
EOF


# 取得本機私有 IP
export ipaddr=`ip address|grep eth0|grep inet|awk -F ' ' '{print $2}' |awk -F '/' '{print $1}'`

# 加入 Tailscale VPN
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey tskey-auth-kVcSDLXzg511CNTRL-NBKiDsyPMj8jxkCMuzBRj8M6CoN3ubYA1

export tailscale_ip=$(ip -4 addr show tailscale0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

iptables -t nat -A PREROUTING -d $ipaddr -p tcp -j DNAT --to-destination $tailscale_ip



if [ -f /etc/kubernetes/kubelet.conf ]; then
  echo "[INFO] 此節點可能已經加入過 Cluster，跳過 Join。"
  exit 0
fi

# 設定 sysctl 參數
tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# 取得 join command
# aws s3 cp s3://${s3buckit_name}/join_command.sh /tmp/.
# chmod +x /tmp/join_command.sh
# bash /tmp/join_command.sh

kubeadm join 100.110.24.114:6443 --token 8qdsgo.iy40tehjprc35xxxx --discovery-token-ca-cert-hash sha256:6907be8b69e1c9dc99c0c6e6e447a36abf9dad3abe3a87f8e2xxxxxx

sysctl --system

# 設定 kubelet 允許 unsafe sysctls
CONF_FILE="/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
cp "$CONF_FILE" "$CONF_FILE bak"
sed -i '/^Environment="KUBELET_CONFIG_ARGS=/ s|"$| --allowed-unsafe-sysctls=net.ipv4.conf.*,net.ipv4.ip_forward"|' "$CONF_FILE"
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart kubelet


echo "203.64.95.35  harbor.antslab.local" | sudo tee -a /etc/hosts

