{{- define "nodejs-service.name" -}}
{{- default .Chart.Name .Values.appName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "nodejs-service.fullname" -}}
{{- if .Values.appName }}
{{- .Values.appName | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "nodejs-service.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{ include "nodejs-service.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "nodejs-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nodejs-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
