{{- define "external.nodeport" -}} {{- $replicas := .Values.spec.kafka.replicas | int }} {{- $advertisedHost := .Values.spec.kafka.listeners.external.overrides.advertisedHost }} {{- $advertisedPort := .Values.spec.kafka.listeners.external.overrides.brokers.advertisedPort | int   }} {{- range $i, $e := until $replicas }}
          - broker: {{ $i }}
            advertisedHost: {{ $advertisedHost }}
            advertisedPort: {{ add $advertisedPort $i }}
{{- end -}}
{{- end -}}

{{- define "externalssl.nodeport" -}} {{- $replicas := .Values.spec.kafka.replicas | int }} {{- $advertisedHost := .Values.spec.kafka.listeners.external.overrides.advertisedHost }} {{- $advertisedPort := .Values.spec.kafka.listeners.externalssl.overrides.brokers.advertisedPort | int   }} {{- range $i, $e := until $replicas }}
          - broker: {{ $i }}
            advertisedHost: {{ $advertisedHost }}
            advertisedPort: {{ add $advertisedPort $i }}
{{- end -}}
{{- end -}}

{{- define "kafka.storagevolumes" -}} {{- $replicas := .Values.spec.kafka.replicas | int }} {{- $storageClass := .Values.spec.kafka.storageVolumes.storageClass }} {{- $type := .Values.spec.kafka.storageVolumes.type  }} {{- $deleteClaim := .Values.spec.kafka.storageVolumes.deleteClaim  }} {{- $size := .Values.spec.kafka.storageVolumes.size  }} {{- range $i, $e := until $replicas }}
          - id: {{ $i }}
            class: {{ $storageClass }}
            type: {{ $type }}
            size: {{ $size }}
            deleteClaim: {{ $deleteClaim }}
{{- end -}}
{{- end -}}

{{- define "kafka.externalservice" -}} 
{{- $replicas := .Values.spec.kafka.replicas | int }}
{{- $advertisedPort := .Values.spec.kafka.listeners.external.overrides.brokers.advertisedPort | int   }}
{{- $targetPort := .Values.spec.kafka.listeners.external.port | int }}
{{- $externalTrafficPolicy := .Values.kafkaService.externalTrafficPolicy}}
{{- $tcpname := .Values.kafkaService.ports.tcpname }} 
{{- $protocol := .Values.kafkaService.ports.protocol  }} 
{{- $type := .Values.kafkaService.ports.type  }} 

{{- if .Values.kafkaService.fixNodePort.enable  -}}
{{- range $i, $e := until $replicas }}
apiVersion: v1
kind: Service
metadata:
  name: {{ template "kafka.fullname" $ }}-{{ $i }}
  namespace: {{ template "namespace" $ }}
  annotations:
   "helm.sh/resource-policy": keep
spec:
  externalTrafficPolicy: {{ $externalTrafficPolicy }}
  ports:
  - name: {{ $tcpname }}
    nodePort: {{ add $advertisedPort $i }}
    port: {{ add $advertisedPort $i }}
    protocol: {{ $protocol }}
    targetPort: {{ $targetPort }}
  selector:
    statefulset.kubernetes.io/pod-name: {{ template "kafka.fullname" $ }}-kafka-{{ $i }}
    strimzi.io/cluster: {{ template "kafka.fullname" $ }}
    strimzi.io/kind: Kafka
    strimzi.io/name: {{ template "kafka.fullname" $ }}-kafka
  sessionAffinity: None
  type: {{ $type }}
status:
  loadBalancer: {}
---
{{- end -}}
{{- else -}}
{{- range $i, $e := until $replicas }}
apiVersion: v1
kind: Service
metadata:
  name: {{ template "kafka.fullname" $ }}-{{ $i }}
  namespace: {{ template "namespace" $ }}
  annotations:
   "helm.sh/resource-policy": keep
spec:
  externalTrafficPolicy: {{ $externalTrafficPolicy }}
  ports:
  - name: {{ $tcpname }}
    port: {{ add $advertisedPort $i }}
    protocol: {{ $protocol }}
    targetPort: {{ $targetPort }}
  selector:
    statefulset.kubernetes.io/pod-name: {{ template "kafka.fullname" $ }}-kafka-{{ $i }}
    strimzi.io/cluster: {{ template "kafka.fullname" $ }}
    strimzi.io/kind: Kafka
    strimzi.io/name: {{ template "kafka.fullname" $ }}-kafka
  sessionAffinity: None
  type: {{ $type }}
status:
  loadBalancer: {}
---
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "kafka.externalsslservice" -}} 
{{- $replicas := .Values.spec.kafka.replicas | int }}
{{- $advertisedPort := .Values.spec.kafka.listeners.externalssl.overrides.brokers.advertisedPort | int   }}
{{- $targetPort := .Values.spec.kafka.listeners.externalssl.port | int }}
{{- $externalTrafficPolicy := .Values.kafkaService.externalTrafficPolicy }}
{{- $tcpname := .Values.kafkaService.ports.tcpname  }} 
{{- $protocol := .Values.kafkaService.ports.protocol  }} 
{{- $type := .Values.kafkaService.ports.type }} 

{{- if .Values.kafkaService.fixNodePort.enable  -}}
{{- range $i, $e := until $replicas }}
apiVersion: v1
kind: Service
metadata:
  name: {{ template "kafka.fullname" $ }}-ssl-{{ $i }}
  namespace: {{ template "namespace" $ }}
  annotations:
   "helm.sh/resource-policy": keep
spec:
  externalTrafficPolicy: {{ $externalTrafficPolicy }}
  ports:
  - name: {{ $tcpname }}
    nodePort: {{ add $advertisedPort $i }}
    port: {{ add $advertisedPort $i }}
    protocol: {{ $protocol }}
    targetPort: {{ $targetPort }}
  selector:
    statefulset.kubernetes.io/pod-name: {{ template "kafka.fullname" $ }}-kafka-{{ $i }}
    strimzi.io/cluster: {{ template "kafka.fullname" $ }}
    strimzi.io/kind: Kafka
    strimzi.io/name: {{ template "kafka.fullname" $ }}-kafka
  sessionAffinity: None
  type: {{ $type }}
status:
  loadBalancer: {}
---
{{- end -}}
{{- else -}}
{{- range $i, $e := until $replicas }}
apiVersion: v1
kind: Service
metadata:
  name: {{ template "kafka.fullname" $ }}-ssl-{{ $i }}
  namespace: {{ template "namespace" $ }}
  annotations:
   "helm.sh/resource-policy": keep
spec:
  externalTrafficPolicy: {{ $externalTrafficPolicy }}
  ports:
  - name: {{ $tcpname }}
    port: {{ add $advertisedPort $i }}
    protocol: {{ $protocol }}
    targetPort: {{ $targetPort }}
  selector:
    statefulset.kubernetes.io/pod-name: {{ template "kafka.fullname" $ }}-kafka-{{ $i }}
    strimzi.io/cluster: {{ template "kafka.fullname" $ }}
    strimzi.io/kind: Kafka
    strimzi.io/name: {{ template "kafka.fullname" $ }}-kafka
  sessionAffinity: None
  type: {{ $type }}
status:
  loadBalancer: {}
---
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "namespace" -}} 
{{ .Release.Namespace }}
{{- end -}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kafka.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kafka.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kafka.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kafka.labels" -}}
helm.sh/chart: {{ include "kafka.chart" . }}
{{ include "kafka.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kafka.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kafka.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- range $key, $value := .Values.global.podLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kafka.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kafka.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
