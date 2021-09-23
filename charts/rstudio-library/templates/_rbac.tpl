{{- /*
  Define and output rbac for rstudio-launcher
  Takes a dict:
    "namespace": "the namespace to deploy the serviceAccount into"
    "targetNamespace": "the namespace to give privileges to. Defaults to $namespace"
    "serviceAccountName": "the name of the service account"
    "roleName": "the role name. Defaults to serviceAccountName"
    "removeNamespaceReferences": "whether to remove namespace references"
    "serviceAccountCreate": "whether to create the service account"
    "serviceAccountAnnotations": "annotation object for the serviceAccount"
    "clusterRoleCreate": "whether or not to create the ClusterRole that allows access to the nodes API"
*/ -}}
{{- define "rstudio-library.rbac" -}}
{{- $serviceAccountAnnotations := default (dict) .serviceAccountAnnotations }}
{{- $serviceAccountCreate := default true .serviceAccountCreate }}
{{- $serviceAccountName := .serviceAccountName }}
{{- $roleName := default $serviceAccountName .roleName }}
{{- $removeNamespaceReferences := default false .removeNamespaceReferences }}
{{- $namespace := default "default" .namespace }}
{{- $targetNamespace := default $namespace .targetNamespace }}
{{- $allNamespaces := list $targetNamespace }}
{{- $clusterRoleCreate := default false .clusterRoleCreate }}
{{- if $clusterRoleCreate }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ $roleName }}
rules:
  - apiGroups:
      - ""
    resources:
      - "nodes"
    verbs:
      - "get"
      - "list"
      - "watch"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ $roleName }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ $roleName }}
subjects:
  - kind: ServiceAccount
    name: {{ $serviceAccountName }}
    namespace: {{ $namespace }}
{{- end }}
{{- if $serviceAccountCreate }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $serviceAccountName }}
  {{- if not $removeNamespaceReferences }}
  namespace: {{ $namespace }}
  {{- end }}
  {{- with $serviceAccountAnnotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- range $ns := $allNamespaces }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $roleName }}
  {{- if not $removeNamespaceReferences }}
  namespace: {{ $ns }}
  {{- end }}
rules:
  - apiGroups:
      - ""
    resources:
      - "pods"
      - "pods/log"
      - "pods/attach"
    verbs:
      - "get"
      - "create"
      - "update"
      - "patch"
      - "watch"
      - "list"
      - "delete"
  - apiGroups:
      - ""
    resources:
      - "events"
    verbs:
      - "watch"
  - apiGroups:
      - ""
    resources:
      - "services"
    verbs:
      - "create"
      - "get"
      - "watch"
      - "list"
      - "delete"
  - apiGroups:
      - "batch"
    resources:
      - "jobs"
    verbs:
      - "create"
      - "update"
      - "patch"
      - "get"
      - "watch"
      - "list"
      - "delete"
  - apiGroups:
      - "metrics.k8s.io"
    resources:
      - "pods"
    verbs:
      - "get"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ $roleName }}
  {{- if not $removeNamespaceReferences }}
  namespace: {{ $ns }}
  {{- end }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ $roleName }}
subjects:
  - kind: ServiceAccount
    name: {{ $serviceAccountName }}
    {{- if not $removeNamespaceReferences }}
    namespace: {{ $namespace }}
    {{- end }}
{{- end }}
{{- end }}
