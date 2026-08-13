{{/*
Return the Chart Name.
*/}}
{{- define "common-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end -}}


{{/*
Return the fully qualified application name.
Example:
auth
cart
orders etc
*/}}
{{- define "common-chart.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}


{{/* 
Common labels shared by all resources.
*/}}
{{- define "common-chart.labels" -}}
app.kubernetes.io/name: {{ include "common-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Determine ServiceAccount name.
*/}}
{{- define "common-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{ .Values.serviceAccount.name }}
{{- else -}}
{{ include "common-chart.fullname" . }}
{{- end -}}
{{- end -}}