# Version: 2.3.1
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
  labels:
    app.kubernetes.io/managed-by: "launcher"
    job-name: {{ toYaml .Job.id }}
    {{- with .Job.metadata.service.labels }}
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
  type: NodePort
