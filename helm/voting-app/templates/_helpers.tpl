{{- define "votingApp.labels" -}}
app.kubernetes.io/part-of: example-voting-app
app.kubernetes.io/managed-by: {{ .Release.Service }}
capstone.tsacademy/project: ship-it
{{- end }}

{{- define "votingApp.componentLabels" -}}
{{- $component := .component }}
{{- $root := .context }}
app.kubernetes.io/name: {{ $component }}
app.kubernetes.io/component: {{ $component }}
app: {{ $component }}
{{ include "votingApp.labels" $root }}
{{- end }}

{{- define "votingApp.selectorLabels" -}}
app: {{ .component }}
{{- end }}

{{- define "votingApp.podSecurityContext" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{- define "votingApp.containerSecurityContext" -}}
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
{{- end }}
