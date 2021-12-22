{{- /*
  Determine and return the Ingress API version
*/ -}}
{{- define "rstudio-library.ingress.apiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion -}}
networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion }}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
{{- end -}}
{{- end -}}{{- /* end define template */ -}}

{{- /*
  Define the backend for an Ingress path
  Takes a dict:
    "apiVersion": "the API version for the Ingress resource"
    "svcName": "the target service name"
    "svcPort": "The target service port"
*/ -}}
{{- define "rstudio-library.ingress.backend" -}}
{{- if or (eq .apiVersion "extensions/v1beta1") (eq .apiVersion "networking.k8s.io/v1beta1") -}}
serviceName: {{ .svcName }}
servicePort: {{ .svcPort }}
{{- else -}}
service:
  name: {{ .svcName }}
  port:
    {{- if typeIs "string" .svcPort }}
    name: {{ .svcPort }}
    {{- else if or (typeIs "int" .svcPort) (typeIs "float64" .svcPort) }}
    number: {{ .svcPort | int }}
    {{- end }}
{{- end -}}
{{- end -}}{{- /* end define template */ -}}

{{- /*
  Return true if the apiVersion supports ingressClassName and false otherwise
  Takes an Ingress API version:
    "the API version for the Ingress resource"
*/ -}}
{{- define "rstudio-library.ingress.supportsIngressClassName" -}}
{{- if or (eq . "extensions/v1beta1") (eq . "networking.k8s.io/v1beta1") -}}
false
{{- else -}}
true
{{- end -}}
{{- end -}}{{- /* end define template */ -}}

{{- /*
  Return true if the apiVersion supports pathType and false otherwise
  Takes an Ingress API version:
    "the API version for the Ingress resource"
*/ -}}
{{- define "rstudio-library.ingress.supportsPathType" -}}
{{- if or (eq . "extensions/v1beta1") (eq . "networking.k8s.io/v1beta1") -}}
false
{{- else -}}
true
{{- end -}}
{{- end -}}{{- /* end define template */ -}}
