#!/bin/bash
# Variant C: ImagePullBackOff due to non-existent image tag.
# The Deployment references nginx:99.0-alpine which does not exist on Docker Hub.
# Pods remain in ImagePullBackOff / ErrImagePull indefinitely.

# ─── Install Tools ────────────────────────────────────────────────────────────
install_k9s() {
  local ver
  ver=$(curl -sf "https://api.github.com/repos/derailed/k9s/releases/latest" \
    | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null) || ver="v0.32.5"
  curl -sL "https://github.com/derailed/k9s/releases/download/${ver}/k9s_Linux_amd64.tar.gz" \
    | tar xz -C /usr/local/bin k9s 2>/dev/null || true
}

install_stern() {
  local ver
  ver=$(curl -sf "https://api.github.com/repos/stern/stern/releases/latest" \
    | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null) || ver="v1.31.0"
  curl -sL "https://github.com/stern/stern/releases/download/${ver}/stern_linux_amd64.tar.gz" \
    | tar xz -C /usr/local/bin stern 2>/dev/null || true
}

install_kubectx() {
  curl -sL https://github.com/ahmetb/kubectx/releases/latest/download/kubectx \
    -o /usr/local/bin/kubectx && chmod +x /usr/local/bin/kubectx || true
  curl -sL https://github.com/ahmetb/kubectx/releases/latest/download/kubens \
    -o /usr/local/bin/kubens && chmod +x /usr/local/bin/kubens || true
}

install_yq() {
  local ver
  ver=$(curl -sf "https://api.github.com/repos/mikefarah/yq/releases/latest" \
    | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null) || ver="v4.45.1"
  curl -sL "https://github.com/mikefarah/yq/releases/download/${ver}/yq_linux_amd64" \
    -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq || true
}

setup_history_logging() {
  cat >> /root/.bashrc << 'BASHRC'
export HISTFILE=/root/.interview_history
export HISTTIMEFORMAT="%F %T "
export HISTSIZE=10000
export HISTFILESIZE=10000
export PROMPT_COMMAND="history -a"
BASHRC
}

install_k9s &
install_stern &
install_kubectx &
install_yq &
setup_history_logging
wait

# ─── Deploy Broken State ──────────────────────────────────────────────────────
# Image tag nginx:99.0-alpine does not exist. The correct tag is nginx:alpine.
# A previous release used nginx:alpine and worked fine. This deployment
# introduced a bad tag reference during a manifest refactor.
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: mobility
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mobility-config
  namespace: mobility
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  DATABASE_URL: "postgres://mobility:s3cr3t@postgres.mobility.svc.cluster.local:5432/mobility"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mobility-api
  namespace: mobility
  annotations:
    kubernetes.io/change-cause: "updated to v1.4.2, bumped base image"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mobility-api
  template:
    metadata:
      labels:
        app: mobility-api
        version: "1.4.2"
    spec:
      containers:
      - name: api
        image: nginx:99.0-alpine
        ports:
        - containerPort: 80
          name: http
        envFrom:
        - configMapRef:
            name: mobility-config
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: mobility-api
  namespace: mobility
spec:
  selector:
    app: mobility-api
  ports:
  - name: http
    port: 80
    targetPort: http
  type: ClusterIP
EOF

# Allow time for ImagePullBackOff to appear
sleep 20

touch /tmp/background-done
