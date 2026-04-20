#!/bin/bash
# Variant A: CrashLoopBackOff due to missing ConfigMap key
# The Deployment references DATABASE_URL (optional: true) which is absent from the ConfigMap.
# The container starts, finds the env var empty, logs a fatal error, and exits → CrashLoopBackOff.

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
# ConfigMap has DB_HOST and DB_PORT, but NOT DATABASE_URL.
# The Deployment requests DATABASE_URL with optional:true, so the container starts
# with an empty env var, immediately exits, and enters CrashLoopBackOff.
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
  DB_HOST: "postgres.mobility.svc.cluster.local"
  DB_PORT: "5432"
  APP_ENV: "production"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mobility-api
  namespace: mobility
  annotations:
    deployment.kubernetes.io/revision: "2"
    kubernetes.io/change-cause: "updated to v1.4.2 with new config reference"
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
        image: nginx:alpine
        command: ["/bin/sh", "-c"]
        args:
          - |
            echo "Starting mobility-api v1.4.2..."
            if [ -z "$DATABASE_URL" ]; then
              echo "FATAL: DATABASE_URL is not set. Cannot connect to database. Exiting."
              exit 1
            fi
            echo "Database configured. Starting HTTP server..."
            exec nginx -g 'daemon off;'
        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: mobility-config
              key: DATABASE_URL
              optional: true
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: mobility-config
              key: APP_ENV
        ports:
        - containerPort: 80
          name: http
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

# Allow time for pods to attempt start and enter CrashLoopBackOff
sleep 30

touch /tmp/background-done
