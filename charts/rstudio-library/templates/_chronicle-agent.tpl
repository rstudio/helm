{{/*
Attempts to determine an image tag for the chronicle-agent image by looking up a Chronicle server in the current
namespace. If no server is found, it will default to "latest". If a tag is specified in the passed config, it will be
used instead of the server tag.
Takes a dict:
    - .chronicleAgent: the chronicle-agent config
        - .chronicleAgent.image.registry: the registry to use for the image
        - .chronicleAgent.image.repository: the repository to use for the image
        - .chronicleAgent.image.tag: the tag to use for the image (optional)
        - .chronicleAgent.serverNamespace: the namespace to search for the Chronicle server, defaults to the current release namespace
 */}}
{{- define "rstudio-library.chronicle-agent.image" }}
{{- $registry := required "registry must be specified for the chronicle-agent config." .chronicleAgent.image.registry }}
{{- $repository := required "repository must be specified for the chronicle-agent config." .chronicleAgent.image.repository }}
{{- $version := "latest" }}
{{- if not .chronicleAgent.image.tag }}
{{- range $index, $service := (lookup "v1" "Service" (default .Release.Namespace .chronicleAgent.serverNamespace) "").items }}
{{- $name := get $service.metadata.labels "app.kubernetes.io/name" }}
{{- $component := get $service.metadata.labels "app.kubernetes.io/component" }}
{{- if and (contains "posit-chronicle" $name) (eq $component "server") }}
{{- $version = get $service.metadata.labels "app.kubernetes.io/version" }}
{{- end }}
{{- end }}
{{- else }}
{{- $version = .chronicleAgent.image.tag }}
{{- end }}
{{ $registry }}/{{ $repository }}:{{ $version }}
{{- end }}

{{/*
Attempts to determine the server address for the chronicle-agent image by looking up a Chronicle server in the current
namespace. If no server is found, it will default to "". If a serverAddress is specified in the passed config,
it will be used instead of the server address.
Takes a dict:
    - .chronicleAgent: the chronicle-agent config
        - .chronicleAgent.serverAddress: the server address to use for the image (optional)
        - .chronicleAgent.serverNamespace: the namespace to search for the Chronicle server, defaults to the current release namespace
*/}}
{{- define "rstudio-library.chronicle-agent.serverAddress" }}
{{- if .chronicleAgent.serverAddress }}
{{ .chronicleAgent.serverAddress}}
{{- else }}
{{- range $index, $service := (lookup "v1" "Service" (default .Release.Namespace .chronicleAgent.serverNamespace) "").items }}
{{- $name := get $service.metadata.labels "app.kubernetes.io/name "}}
{{- $component := get $service.metadata.labels "app.kubernetes.io/component "}}
{{- if and (contains "posit-chronicle" $name) (eq $component "server") }}
{{ $name }}.{{ $service.metadata.namespace }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
