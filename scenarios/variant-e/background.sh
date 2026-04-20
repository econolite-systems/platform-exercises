#!/bin/bash
# Variant E: Helm upgrade introduced replicaCount: 0.
# The Deployment is applied directly via kubectl with replicas: 0 to guarantee
# it lands, but the Helm chart and a simulated release history are also written
# to disk so the candidate can discover the cause via helm history / helm get values.

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

# ─── Write Helm Chart to Disk ─────────────────────────────────────────────────
# The chart is present so the candidate can inspect it and run helm commands.
# Actual deploy is via kubectl to avoid helm install timing issues.
mkdir -p /root/mobility-chart/templates

cat > /root/mobility-chart/Chart.yaml << 'CHARTEOF'
apiVersion: v2
name: mobility-api
description: Centracs Mobility API service
type: application
version: 1.4.2
appVersion: "1.4.2"
CHARTEOF

cat > /root/mobility-chart/values.yaml << 'VALEOF'
replicaCount: 2

image:
  repository: nginx
  tag: alpine
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"

env:
  APP_ENV: "production"
  DATABASE_URL: "postgres://mobility:s3cr3t@postgres.mobility.svc.cluster.local:5432/mobility"
VALEOF

# Simulate the bad override values file used in the pipeline
cat > /root/mobility-chart/override-values.yaml << 'OVERRIDEEOF'
replicaCount: 0
OVERRIDEEOF

cat > /root/mobility-chart/templates/deployment.yaml << 'DEPLOYEOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mobility-api
  namespace: mobility
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: mobility-api
  template:
    metadata:
      labels:
        app: mobility-api
    spec:
      containers:
      - name: api
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: 80
          name: http
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
DEPLOYEOF

# ─── Deploy Broken State via kubectl ─────────────────────────────────────────
# replicas: 0 — Deployment exists and is valid, zero pods intentionally.
# Mirrors what `helm upgrade --set replicaCount=0` would have produced.
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
  DATABASE_URL: "postgres://mobility:s3cr3t@postgres.mobility.svc.cluster.local:5432/mobility"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mobility-api
  namespace: mobility
  annotations:
    kubernetes.io/change-cause: "helm upgrade mobility --set replicaCount=0"
spec:
  replicas: 0
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

sleep 5

touch /tmp/background-done


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

# ─── Write Helm Chart ─────────────────────────────────────────────────────────
mkdir -p /root/mobility-chart/templates

cat > /root/mobility-chart/Chart.yaml << 'EOF'
apiVersion: v2
name: mobility-api
description: Centracs Mobility API service
type: application
version: 1.4.2
appVersion: "1.4.2"
EOF

cat > /root/mobility-chart/values.yaml << 'EOF'
replicaCount: 2

image:
  repository: nginx
  tag: alpine
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"

env:
  APP_ENV: "production"
  DATABASE_URL: "postgres://mobility:s3cr3t@postgres.mobility.svc.cluster.local:5432/mobility"
EOF

cat > /root/mobility-chart/templates/_helpers.tpl << 'EOF'
{{- define "mobility-api.name" -}}
{{- .Chart.Name }}
{{- end }}

{{- define "mobility-api.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mobility-api.labels" -}}
app: {{ include "mobility-api.name" . }}
version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
EOF

cat > /root/mobility-chart/templates/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: mobility
EOF

cat > /root/mobility-chart/templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mobility-api
  namespace: mobility
  labels:
    {{- include "mobility-api.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "mobility-api.name" . }}
  template:
    metadata:
      labels:
        {{- include "mobility-api.labels" . | nindent 8 }}
    spec:
      containers:
      - name: api
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: 80
          name: http
        env:
        {{- range $key, $val := .Values.env }}
        - name: {{ $key }}
          value: {{ $val | quote }}
        {{- end }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
EOF

cat > /root/mobility-chart/templates/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: mobility-api
  namespace: mobility
  labels:
    {{- include "mobility-api.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ include "mobility-api.name" . }}
  ports:
  - name: http
    port: {{ .Values.service.port }}
    targetPort: http
EOF

# ─── Deploy: Good State First, Then Break It ──────────────────────────────────
kubectl create namespace mobility --dry-run=client -o yaml | kubectl apply -f -

# Release 1 — healthy (replicaCount: 2)
# No --wait: we only need the Deployment object to exist before we upgrade to 0.
# --wait can time out on a slow cluster, causing the release to be never created.
helm install mobility /root/mobility-chart \
  --namespace mobility \
  --set replicaCount=2

# Give the API server a moment to persist the release secret before upgrading
sleep 5

# Release 2 — broken (replicaCount: 0, simulates accidental override in pipeline)
helm upgrade mobility /root/mobility-chart \
  --namespace mobility \
  --set replicaCount=0

sleep 5

touch /tmp/background-done
