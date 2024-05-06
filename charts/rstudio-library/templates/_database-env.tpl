{{- /*
  Define environment variables for database password configuration
  Takes a dict:
    "envVarPrefix": "the env var prefix, e.g., WORKBENCH"
    "database": "the database configuration values"
*/ -}}
{{- define "rstudio-library.database-env" -}}
{{- if .database.password.secret }}
- name: {{ .envVarPrefix }}_POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .database.password.secret }}
      key: {{ .database.password.secretKey }}
{{- end }}
{{- end -}}{{- /* end define template */ -}}
