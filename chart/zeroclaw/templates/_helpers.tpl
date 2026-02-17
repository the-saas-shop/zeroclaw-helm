{{/*
Expand the name of the chart.
*/}}
{{- define "zeroclaw.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "zeroclaw.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "zeroclaw.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "zeroclaw.labels" -}}
helm.sh/chart: {{ include "zeroclaw.chart" . }}
{{ include "zeroclaw.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "zeroclaw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zeroclaw.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use.
*/}}
{{- define "zeroclaw.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "zeroclaw.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Resolve API key secret name.
*/}}
{{- define "zeroclaw.apiKeySecretName" -}}
{{- if .Values.secret.create -}}
{{- printf "%s-secret" (include "zeroclaw.fullname" .) -}}
{{- else if .Values.secret.existingSecret -}}
{{- .Values.secret.existingSecret -}}
{{- else -}}
{{- fail "secret.existingSecret must be set when secret.create=false" -}}
{{- end -}}
{{- end -}}

{{/*
Resolve persistence claim name.
*/}}
{{- define "zeroclaw.pvcName" -}}
{{- if .Values.persistence.existingClaim -}}
{{- .Values.persistence.existingClaim -}}
{{- else -}}
{{- printf "%s-data" (include "zeroclaw.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Resolve channel secrets secret name.
Returns empty string if no channel secrets are configured.
*/}}
{{- define "zeroclaw.channelSecretsName" -}}
{{- if .Values.channelSecrets.existingSecret -}}
{{- .Values.channelSecrets.existingSecret -}}
{{- else if .Values.channelSecrets.create -}}
{{- printf "%s-channel-secrets" (include "zeroclaw.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Check if channel secrets volume should be mounted.
Returns "true" if either create or existingSecret is set.
*/}}
{{- define "zeroclaw.hasChannelSecrets" -}}
{{- if or .Values.channelSecrets.create .Values.channelSecrets.existingSecret -}}
true
{{- end -}}
{{- end -}}

{{/*
Helper to render a TOML string list from a Helm list value.
Usage: {{ include "zeroclaw.tomlStringList" .Values.config.autonomy.allowedCommands }}
Output: ["git", "npm", "cargo"]
*/}}
{{- define "zeroclaw.tomlStringList" -}}
[{{ range $i, $v := . }}{{ if $i }}, {{ end }}{{ $v | quote }}{{ end }}]
{{- end -}}
