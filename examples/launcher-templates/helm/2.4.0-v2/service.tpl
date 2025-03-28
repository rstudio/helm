# Version: 2.4.0
# DO NOT MODIFY the "Version: " key
# Helm Version: v2
{{- $templateData := include "rstudio-library.templates.data" nil | mustFromJson }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Job.serviceName }}
  annotations:
    {{- with .Job.metadata.service.annotations }}
    {{- range $key, $val := . }}
    {{ $key }}: {{ toYaml $val | indent 4 | trimPrefix (repeat 4 " ") }}
    {{- end }}
    {{- end }}
    {{- with $templateData.service.annotations }}
    {{- range $key, $val := . }}
    {{ $key }}: {{ toYaml $val | indent 4 | trimPrefix (repeat 4 " ") }}
    {{- end }}
    {{- end }}
  labels:
    app.kubernetes.io/managed-by: "launcher"
    job-name: {{ toYaml .Job.id }}
    {{- with .Job.instanceId }}
    launcher-instance-id: {{ toYaml . }}
    {{- end }}
    {{- with .Job.metadata.service.labels }}
    {{- range $key, $val := . }}
    {{ $key }}: {{ toYaml $val | indent 8 | trimPrefix (repeat 8 " ") }}
    {{- end }}
    {{- end }}
    {{- with $templateData.service.labels }}
    {{- range $key, $val := . }}
    {{ $key }}: {{ toYaml $val | indent 8 | trimPrefix (repeat 8 " ") }}
    {{- end }}
    {{- end }}
spec:
  ports:
    {{- $i := 0 }}
    {{- range .Job.exposedPorts }}
    {{- if not .publishedPort }}
    - name: {{ printf "port%d" $i }}
      protocol: {{ .protocol }}
      port: {{ .targetPort }}
      targetPort: {{ .targetPort }}
      {{- $i = add $i 1 }}
    {{- end }}
    {{- end }}
  selector:
    job-name: {{toYaml .Job.id }}
  clusterIP: ''
  type: {{ $templateData.service.type }}
