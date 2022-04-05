# Version: 1
# connect-job-template-version: 1.0
{{- /* syntax documented in https://docs.rstudio.com/job-launcher/latest/kube.html#modifying-templates */ -}}

{{- /* Connect passes a JobInfo structure through the first .Job.tag */ -}}
{{- $tag := mustFirst .Job.tags }}
{{- $jobInfoObj := mustFromJson $tag }}

apiVersion: batch/v1
kind: Job
metadata:
  generateName: {{ toYaml .Job.generateName }}
  labels:
{{ include "connect-job-labels" $jobInfoObj | indent 4 }}
  annotations:
{{ include "connect-job-annotations" $jobInfoObj | indent 4 }}
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
{{ include "connect-pod-labels" $jobInfoObj | indent 8 }}
      annotations:
{{ include "connect-pod-annotations" $jobInfoObj | indent 8 }}
        stdin: {{ toYaml .Job.stdin }}
        user: {{ toYaml .Job.user }}
        name: {{ toYaml .Job.name }}
        service_ports: {{ toYaml .Job.servicePortsJson }}
      generateName: {{ toYaml .Job.generateName }}
    spec:
      {{- if .Job.host }}
      nodeName: {{ toYaml .Job.host }}
      {{- end }}
      restartPolicy: Never
      shareProcessNamespace: {{ .Job.shareProcessNamespace }}
      {{- if ne (len .Job.volumes) 0 }}
      volumes:
        {{- range .Job.volumes }}
        - {{ nindent 10 (toYaml .) | trim }}
        {{- end }}
      {{- end }}
      {{- if ne (len .Job.placementConstraints) 0 }}
      nodeSelector:
        {{- range .Job.placementConstraints }}
        {{ .name }}: {{ toYaml .value }}
        {{- end }}
      {{- end }}
      {{- $securityContext := dict }}
      {{- if .Job.container.runAsUserId }}
        {{- $_ := set $securityContext "runAsUser" .Job.container.runAsUserId }}
      {{- end }}
      {{- if .Job.container.runAsGroupId }}
        {{- $_ := set $securityContext "runAsGroup" .Job.container.runAsGroupId }}
      {{- end }}
      {{- if .Job.container.supplementalGroupIds }}
        {{- $groupIds := list }}
        {{- range .Job.container.supplementalGroupIds }}
          {{- $groupIds = append $groupIds . }}
        {{- end }}
        {{- $_ := set $securityContext "supplementalGroups" (cat "[" ($groupIds | join ", ") "]") }}
      {{- end }}
      {{- if $securityContext }}
      securityContext:
        {{- range $key, $val := $securityContext }}
        {{ $key }}: {{ $val }}
        {{- end }}
      {{- end }}
      containers:
        - name: rs-launcher-container
          image: {{ toYaml .Job.container.image }}
          {{- $isShell := false }}
          {{- if .Job.command }}
          command: ['/bin/sh']
          {{- $isShell = true }}
          {{- else }}
          command: [{{ toYaml .Job.exe }}]
          {{- $isShell = false }}
          {{- end }}
          {{- if .Job.stdin }}
          stdin: true
          {{- else }}
          stdin: false
          {{- end }}
          stdinOnce: true
          {{- if .Job.workingDirectory }}
          workingDir: {{ toYaml .Job.workingDirectory }}
          {{- end }}
          {{- if or (ne (len .Job.args) 0) $isShell }}
          args:
            {{- if $isShell }}
            - '-c'
            {{- if ne (len .Job.args) 0 }}
            - {{ .Job.args | join " " | cat .Job.command | toYaml }}
            {{- else }}
            - {{ .Job.command | toYaml }}
            {{- end }}
            {{- else }}
            {{- range .Job.args }}
            - {{ toYaml . }}
            {{- end }}
            {{- end }}
          {{- end }}
          {{- $secrets := list }}
          {{- range .Job.config }}
            {{- if eq .name "secret" }}
              {{- $packedSecret := .value }}
              {{- $secret := dict }}
              {{- $_ := set $secret "secret" (splitList ":" $packedSecret | first) }}
              {{- $_ := set $secret "key" (slice (splitList ":" $packedSecret) 1 2 | first) }}
              {{- $_ := set $secret "name" (splitList ":" $packedSecret | last) }}
              {{- $secrets = append $secrets $secret }}
            {{- end }}
          {{- end }}
          {{- if or (ne (len .Job.environment) 0) (ne (len $secrets) 0) }}
          env:
            {{- range .Job.environment }}
            - name: {{ toYaml .name }}
              value: {{ toYaml .value }}
            {{- end }}
            {{- range $secrets }}
            - name: {{ get . "name"}}
              valueFrom:
                secretKeyRef:
                  name: {{ get . "secret" }}
                  key: {{ get . "key" }}
            {{- end }}
          {{- end }}
          {{- $exposedPorts := list }}
          {{- range .Job.exposedPorts }}
            {{- if .publishedPort }}
              {{- $exposedPorts = append $exposedPorts . }}
            {{- end }}
          {{- end }}
          {{- if ne (len $exposedPorts) 0 }}
          ports:
            {{- range $exposedPorts }}
            - containerPort: {{ .targetPort }}
              hostPort: {{ .publishedPort }}
            {{- end }}
          {{- end }}
          {{- $limits := dict }}
          {{- $requests := dict }}
          {{- range .Job.resourceLimits }}
            {{- if eq .type "cpuCount" }}
              {{- $_ := set $limits "cpu" .value }}
              {{- if ne $.Job.cpuRequestRatio 1.0 }}
                {{- $val := mulf .value $.Job.cpuRequestRatio | toString }}
                {{- $_ := set $requests "cpu" $val }}
              {{- end }}
            {{- else if eq .type "memory" }}
              {{- $_ := set $limits "memory" (printf "%s%s" .value "M") }}
              {{- if ne $.Job.memoryRequestRatio 1.0 }}
                {{- $val := mulf .value $.Job.memoryRequestRatio }}
                {{- $_ := set $requests "memory" (printf "%.2f%s" $val "M") }}
              {{- end }}
            {{- else if eq .type "NVIDIA GPUs" }}
              {{- $val := float64 .value }}
              {{- if ne $val 0.0 }}
                {{- $_ := set $limits "nvidia.com/gpu" $val }}
              {{- end }}
            {{- else if eq .type "AMD GPUs" }}
              {{- $val := float64 .value }}
              {{- if ne $val 0.0 }}
                {{- $_ := set $limits "amd.com/gpu" $val }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if any (ne (len $requests) 0) (ne (len $limits) 0) }}
          resources:
            {{- if ne (len $requests) 0 }}
            requests:
              {{- range $key, $val := $requests }}
              {{ $key }}: {{ toYaml $val }}
              {{- end }}
            {{- end }}
            {{- if ne (len $limits) 0 }}
            limits:
              {{- range $key, $val := $limits }}
              {{ $key }}: {{ toYaml $val }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if ne (len .Job.volumes) 0 }}
          volumeMounts:
            {{- range .Job.volumeMounts }}
            - {{ nindent 14 (toYaml .) | trim }}
            {{- end }}
          {{- end }}
