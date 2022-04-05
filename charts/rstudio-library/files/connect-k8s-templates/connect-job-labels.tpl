{{- /* include file for extracting job labels name / value YAML entry from a JobInfo structure */ -}}
{{- /* NOTE: limitation of one defined function per file, with name same as function (with .tpl file extension) */ -}}
{{- /* syntax documented in https://docs.rstudio.com/job-launcher/latest/kube.html#modifying-templates */ -}}

{{- define "connect-job-labels" }}
  {{- /* first parameter: JobInfo object */ -}}
	{{- range $key, $val := .JobLabels }}
		{{- /* Using nindent to add new lines which are not gobbled up with "{{-" */ -}}
		{{- printf "%s: \"%s\"" $key $val | nindent 0 }}
	{{- end }}
{{- end }}
