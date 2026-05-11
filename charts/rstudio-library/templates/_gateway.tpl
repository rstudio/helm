{{- /*
  Gateway API group/version for HTTPRoute and related resources
*/ -}}
{{- define "rstudio-library.gateway.apiVersion" -}}
gateway.networking.k8s.io/v1
{{- end -}}

{{- /*
  Map Ingress pathType values to Gateway API HTTPPathMatch type values.
  Takes the pathType string (e.g. Prefix, Exact, ImplementationSpecific).
*/ -}}
{{- define "rstudio-library.gateway.ingressPathTypeToGateway" -}}
{{- $t := . | default "Prefix" | toString -}}
{{- if eq $t "Prefix" -}}
PathPrefix
{{- else if eq $t "Exact" -}}
Exact
{{- else if eq $t "ImplementationSpecific" -}}
ImplementationSpecific
{{- else if eq $t "PathPrefix" -}}
PathPrefix
{{- else if eq $t "RegularExpression" -}}
RegularExpression
{{- else -}}
PathPrefix
{{- end -}}
{{- end -}}

{{- /*
  YAML body for HTTPPathMatch (path.type and path.value), indented under "path:".
  Takes a dict:
    "pathData" — same as ingress path entry: string or map with .path and optional .pathType
*/ -}}
{{- define "rstudio-library.gateway.httpPathMatchBody" -}}
{{- $pathData := .pathData -}}
{{- $path := "/" -}}
{{- $pathType := "Prefix" -}}
{{- if kindIs "string" $pathData -}}
{{- $path = $pathData -}}
{{- else -}}
{{- $path = $pathData.path -}}
{{- if hasKey $pathData "pathType" -}}
{{- $pathType = $pathData.pathType | default "Prefix" -}}
{{- end -}}
{{- end -}}
type: {{ include "rstudio-library.gateway.ingressPathTypeToGateway" $pathType }}
value: {{ $path | quote }}
{{- end -}}

{{- /*
  Kubernetes-safe HTTPRoute name from release fullname and host index (DNS-1123, max 63 chars).
  Takes a dict: "fullName" and "index" (int).
*/ -}}
{{- define "rstudio-library.gateway.httpRouteName" -}}
{{- $fullName := .fullName -}}
{{- $idx := int .index -}}
{{- printf "%s-gw-%d" ($fullName | trunc 56) $idx | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /*
  Service backendRef for HTTPRoute (port must be numeric for standard Service refs).
  Takes a dict: "svcName", "svcPort"
*/ -}}
{{- define "rstudio-library.gateway.serviceBackendRef" -}}
{{- $svcName := .svcName -}}
{{- $svcPort := .svcPort -}}
- name: {{ $svcName }}
  port: {{ $svcPort | int }}
{{- end -}}
