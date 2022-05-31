# Version: 2
# connect-job-template-version: 1.0
{{- /* syntax documented in https://docs.rstudio.com/job-launcher/latest/kube.html#modifying-templates */ -}}

{{- /* Connect passes a JobInfo structure through the first .Job.tag */ -}}
{{- $tag := mustFirst .Job.tags }}
{{- $jobInfoObj := mustFromJson $tag }}

apiVersion: v1
kind: Service
metadata:
  name: {{ .Job.serviceName }}
  labels:
    job-name: {{ toYaml .Job.id }}
{{ include "connect-svc-labels" $jobInfoObj | indent 4 }}
  annotations:
{{ include "connect-svc-annotations" $jobInfoObj | indent 4 }}
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
  type: NodePort
