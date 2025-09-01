# Auto Deployment Kubernetes Cluster in AWS with Terraform

本專案使用 **Terraform** 自動化建立 AWS 上的 Kubernetes 叢集，  
包含 **VPC、子網路、EC2 節點、Security Group** 等資源，不受限於 EKS 服務限制，  
並可選擇安裝基本套件 (如 Helm、CNI)。  

---

## 專案特色

- 使用 IaC 工具 **Terraform** 管理 AWS 資源  
- 自動建立 Kubernetes **Master / Worker Node** 的 EC2 節點  
- 彈性使用 Kubernetes 原生功能，不受 EKS 限制  
- 可整合 **Helm** 自動化部署特定應用環境  
- 支援 **Tailscale VPN**，跨雲串接本地端叢集 (如 PVE、On-Prem K8s) (選用)  

---

## 前置需求

1. [Terraform](https://developer.hashicorp.com/terraform/downloads)  
2. [AWS CLI](https://docs.aws.amazon.com/cli/)  
   - 需先設定使用者 Auth Token 環境變數  
3. Kubernetes Cluster (選擇以下兩種方式)  
   - 本地端已部署之 K8s Cluster，並加入 EC2 作為 Worker Node  
   - 直接於 AWS 上建立 Kubernetes Cluster  
4. [Helm](https://helm.sh/) (選用)  
5. Harbor (選用) – 私有容器倉庫  

---

## AWS 基礎設置 (可自行調整)

- **Region** : `ap-northeast-1`  
- **AMI** : Ubuntu  
- **VPC** :  
  - `cidr_block`: `192.0.0.0/16`  
- **Subnet** :  
  - `cidr_block`: `192.0.1.0/24`  
- **Security Group (ec2-sg)** : 開放 Port  
  - `80` – HTTP  
  - `443` – HTTPS  
  - `6443` – K8s API Server  
  - `30000–32767` – K8s NodePort Service  

---

### EC2 Master Node

- **Module** : `ec2_k8s_master`  
- **Path** : `./modules/ec2_k8s_master`  
- **AMI** : Ubuntu  
- **Instance Type** : `t3.medium` (最低需求)  
- **Volume Size** : 30GB (最低需求)  
- 其他設置可參考 `ec2_k8s_master` 模組內說明  

---

### EC2 Worker Node

- **Module** : `ec2_k8s_node`  
- **Path** : `./modules/ec2_k8s_worker`  
- **AMI** : Ubuntu  
- **Instance Type** : `t3.medium` (最低需求)  
- **Volume Size** : 30GB (最低需求)  
- **worker_number** : Worker Node Tag (自訂義)  
- 其他設置可參考 `ec2_k8s_node` 模組內說明  

---

## Helm Charts

### helm-ssh

#### 介紹
透過 Helm Chart 部署一組完整的網路實驗環境，包含:  
1. **NetworkAttachmentDefinition** : 使用 Multus CNI 建立多網卡支援  
2. **Bridge Job** : 自動於節點上建立/刪除 Linux Bridge，模擬 Switch  
3. **Pod 節點** : 具備 SSH 服務的 Pod，可用於下載/客製化靶機環境，並遠端操作  
4. **Router 節點** : 與 Pod 相似，但具備多張虛擬網卡與 IP Forwarding 功能  
5. **Service** : 使用 NodePort 型態，為每個 Pod 的 SSH 服務分配 Port  

*請自行客製化具備 SSH 服務的容器映像檔*

#### 適合應用
- 網路安全演練 (防火牆、網路隔離、攻防演練)  
- 輕量化 CLI 環境，降低資源消耗  

---

### helm-novnc

#### 介紹
透過 Helm Chart 部署 **noVNC** 服務，提供使用者透過瀏覽器直接存取遠端桌面，包含:  
1. **noVNC 前端** : HTML5 + JavaScript 客戶端，僅需瀏覽器即可使用  
2. **websockify Proxy** : 將 WebSocket 流量轉換為 VNC 協定  
3. **VNC Server 容器** : 提供後端桌面環境 (LXDE / XFCE 等輕量 UI)  
4. **Service** : 使用 NodePort 型態，為每個 Pod 的 VNC 服務分配 Port (預設 5901)  

*請自行客製化具備 noVNC 服務的容器映像檔*

#### 適合應用
- 需要 GUI 的網路/資安演練 (如 Wireshark、瀏覽器操作)  
- 提供學員圖形化靶機環境 (GUI-based target machine)  
- 簡化遠端存取流程，無需額外安裝 VNC Client  

---

## 延伸應用

- 可與 **Harbor** 整合，建立私有容器倉庫  
- 搭配 **CI/CD Pipeline**，實現自動化部署/清理  
- 適用於 **混合雲環境** (AWS + PVE Cluster)，進行跨雲網路實驗  
- 支援 **多種 CNI Plugin** 測試 (Calico、Flannel、Multus)  

---
