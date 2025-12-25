{{/*
Expand the name of the chart.
*/}}
{{- define "fjelltrimmen.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fjelltrimmen.fullname" -}}
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
{{- define "fjelltrimmen.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fjelltrimmen.labels" -}}
helm.sh/chart: {{ include "fjelltrimmen.chart" . }}
{{ include "fjelltrimmen.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fjelltrimmen.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fjelltrimmen.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "fjelltrimmen.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "fjelltrimmen.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Return the name used for the CloudNativePG cluster resource. */}}
{{- define "fjelltrimmen.cloudNativePgName" -}}
{{- if .Values.cloudNativePg.nameOverride }}
{{- .Values.cloudNativePg.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-db" (include "fjelltrimmen.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/* Return the name of the secrets created by external-secrets */}}
{{- define "fjelltrimmen.secretsName" -}}
{{- printf "%s-secrets" (include "fjelltrimmen.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
