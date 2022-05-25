# Version: 1
apiVersion: v1
kind: Service
metadata:
  name: {{ .Job.serviceName }}
  labels:
    job-name: {{ toYaml .Job.id }}
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
  type: {{ include "rstudio-helm-service-type" . }}
