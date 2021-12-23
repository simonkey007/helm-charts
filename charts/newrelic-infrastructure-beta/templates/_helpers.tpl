{{/*
Expand the name of the chart.
*/}}
{{- define "newrelic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "newrelic.fullname" -}}
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


{{/* Generate mode label */}}
{{- define "newrelic.mode" }}
{{- if .Values.privileged -}}
privileged
{{- else -}}
unprivileged
{{- end }}
{{- end -}}

{{/* Common labels */}}
{{- define "newrelic.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "newrelic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
mode: {{ template "newrelic.mode" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/* Create the name of the service account to use */}}
{{- define "newrelic.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "newrelic.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the cluster name
*/}}
{{- define "newrelic.cluster" -}}
{{- if .Values.cluster -}}
  {{- .Values.cluster -}}
{{- else if .Values.global -}}
  {{- if .Values.global.cluster -}}
    {{- .Values.global.cluster -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return local licenseKey if set, global otherwise
*/}}
{{- define "newrelic.licenseKey" -}}
{{- if .Values.licenseKey -}}
  {{- .Values.licenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.licenseKey -}}
    {{- .Values.global.licenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the License Key
*/}}
{{- define "newrelic.licenseCustomSecretName" -}}
{{- if .Values.customSecretName -}}
  {{- .Values.customSecretName -}}
{{- else if and .Values.global -}}
  {{- if .Values.global.customSecretName -}}
    {{- .Values.global.customSecretName -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret holding the License Key
*/}}
{{- define "newrelic.licenseSecretName" -}}
{{ include "newrelic.licenseCustomSecretName" . | default (printf "%s-license" (include "newrelic.fullname" . )) }}
{{- end -}}

{{/*
Return the name key for the License Key inside the secret
*/}}
{{- define "newrelic.licenseCustomSecretKey" -}}
{{- if .Values.customSecretLicenseKey -}}
  {{- .Values.customSecretLicenseKey -}}
{{- else if .Values.global -}}
  {{- if .Values.global.customSecretLicenseKey }}
    {{- .Values.global.customSecretLicenseKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name key for the License Key inside the secret
*/}}
{{- define "newrelic.licenseSecretKey" -}}
{{ include "newrelic.licenseCustomSecretKey" . | default "licenseKey" }}
{{- end -}}

{{/*
Returns nrStaging
*/}}
{{- define "newrelic.nrStaging" -}}
{{- if .Values.nrStaging -}}
  {{- .Values.nrStaging -}}
{{- else if .Values.global -}}
  {{- if .Values.global.nrStaging -}}
    {{- .Values.global.nrStaging -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Returns fargate
*/}}
{{- define "newrelic.fargate" -}}
{{- if .Values.fargate -}}
  {{- .Values.fargate -}}
{{- else if .Values.global -}}
  {{- if .Values.global.fargate -}}
    {{- .Values.global.fargate -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/* controlPlane scraper config */}}
{{- define "newrelic.controlPlane.scraperConfigEnabled" -}}
controlPlane:
  enabled: true
{{- end }}

{{/* controlPlane scraper config */}}
{{- define "newrelic.controlPlane.scraperConfig" -}}
{{- (merge (include "newrelic.controlPlane.scraperConfigEnabled" . | fromYaml) .Values.controlPlane.scraperConfig) | toYaml }}
{{- end }}

{{/* kubelet scraper config */}}
{{- define "newrelic.kubelet.scraperConfigEnabled" -}}
kubelet:
  enabled: true
{{- end }}

{{/* kubelet scraper config */}}
{{- define "newrelic.kubelet.scraperConfig" -}}
{{- (merge (include "newrelic.kubelet.scraperConfigEnabled" . | fromYaml) .Values.kubelet.scraperConfig) | toYaml }}
{{- end }}

{{- define "newrelic.deprecatedKubeStateMetrics" -}}
ksm:
  scheme: {{  $.Values.kubeStateMetricsScheme | quote }}
  port: {{  $.Values.kubeStateMetricsPort | quote }}
  staticURL: {{  $.Values.kubeStateMetricsUrl | quote }}
  selector: {{  $.Values.kubeStateMetricsPodLabel | quote }}
  namespace: {{  $.Values.kubeStateMetricsNamespace | quote }}
{{- end -}}

{{/* ksm scraper config */}}
{{- define "newrelic.ksm.scraperConfigEnabled" -}}
ksm:
  enabled: true
{{- end }}

{{/* ksm scraper config */}}
{{- define "newrelic.ksm.scraperConfig" -}}
{{- (merge (include "newrelic.ksm.scraperConfigEnabled" . | fromYaml) .Values.ksm.scraperConfig) | toYaml }}
{{- end }}

{{/*
Returns the list of namespaces where secrets need to be accessed by the controlPlane Scraper to do mTLS Auth
*/}}
{{- define "newrelic.roleBindingNamespaces" -}}
{{ $namespaceList := list }}
{{- range $components := .Values.controlPlane.scraperConfig.controlPlane }}
    {{- range $autodiscover := $components.autodiscover }}
        {{- range $endpoint := $autodiscover.endpoints }}
            {{- if $endpoint.auth }}
            {{- if $endpoint.auth.mtls }}
            {{- if $endpoint.auth.mtls.secretName }}
            {{- $namespace := $endpoint.auth.mtls.secretNamespace | default "default" -}}
            {{- $namespaceList = append $namespaceList $namespace -}}
            {{- end }}
            {{- end }}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end }}
roleBindingNamespaces: {{- uniq $namespaceList | toYaml | nindent 0 }}
{{- end -}}

{{/*
Returns Custom Attributes as a yaml even if formatted as a json string
*/}}
{{- define "newrelic.customAttributes" -}}
{{- if kindOf .Values.customAttributes | eq "string" -}}
{{  .Values.customAttributes }}
{{- else -}}
{{ .Values.customAttributes | toJson | quote  }}
{{- end -}}
{{- end -}}