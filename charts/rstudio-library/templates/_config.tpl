{{- /*
  Takes a map of maps, turns it into a .gcfg (go configuration) file
  Useful for RStudio Connect and RStudio Package Manager
  i.e.
  { "Server" = {"Host" = "value", "another" = ["multiple", "values"]}}
  Valid values depend on the product
*/ -}}

{{- define "rstudio-library.config.gcfg" -}}
{{- range $section,$keys := . -}}
[{{ $section }}]
  {{- range $key, $val := $keys }}
    {{- if kindIs "slice" $val }}
      {{- range $eachval := $val }}
{{ $key }} = {{ $eachval }}
      {{- end }}
    {{- else }}
{{ $key }} = {{ $val }}
    {{- end }}
  {{- end }}

{{ end }}
{{- end -}}

{{- /*
  Takes a map of maps, turns each into a generic text file

  Config data is passed into `.data`
  A comment delimiter (used for keys) is passed as `.commentDelimiter`
*/ -}}
{{- define "rstudio-library.config.txt" -}}
{{- $commentDelim := .commentDelimiter | default "#" }}
{{- range $file, $keys := .data -}}
{{- printf "%s: |" $file | nindent 0 }}
{{- if kindIs "string" $keys }}
  {{- $keys | nindent 2 }}
{{- else }}
{{- range $parent, $child := $keys -}}
  {{- printf "%s %s" (toString $commentDelim) (toString $parent) | nindent 2 }}
  {{- printf "%s" (toString $child) | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- /*
  Normalizes config-file contents into an ordered list of entries.

  Accepts either form:
    - a map of {name: value}, which Go templates iterate in sorted key order
    - a list of single-entry maps, which is iterated in the order it was written

  Templates cannot return values, so the caller passes a dict to write into:
    data: the contents to normalize
    result: a dict, which this sets an "entries" key on. Each entry is a dict
            with a "name" (string) and a "config" (the value written under it)
*/ -}}
{{- define "rstudio-library.config.entries" -}}
{{- $entries := list }}
{{- $data := default (dict) .data }}
{{- if kindIs "slice" $data }}
  {{- range $item := $data }}
    {{- if not (kindIs "map" $item) }}
      {{- fail (print "\n\nEntries written as a list must each be a map of a single name and its value. Instead got '" (kindOf $item) "' : '" (print $item) "'") }}
    {{- end }}
    {{- range $name, $config := $item }}
      {{- $entries = append $entries (dict "name" (toString $name) "config" $config) }}
    {{- end }}
  {{- end }}
{{- else }}
  {{- range $name, $config := $data }}
    {{- $entries = append $entries (dict "name" (toString $name) "config" $config) }}
  {{- end }}
{{- end }}
{{- $_ := set .result "entries" $entries }}
{{- end -}}

{{- /*
  Renders a single ini entry, passed as a dict of {name: value}:
    - a map value becomes a [name] section followed by its key=value pairs
    - a list of maps becomes repeated [name] sections (ini files may have more
      than one section with the same name)
    - anything else becomes a bare name=value line
*/ -}}
{{- define "rstudio-library.config.ini.entry" -}}
{{- range $parent, $child := . -}}
  {{- $sections := ( (kindIs "slice" $child) | ternary $child ( list $child ))}}
  {{- range $i, $section := $sections -}}
    {{- if kindIs "map" $section }}
      {{- printf "[%s]" (toString $parent) | nindent 2 }}
      {{- range $key, $val := $section }}
        {{- printf "%s=%s" (toString $key) (toString $val) | nindent 2 }}
      {{- end }}
      {{- printf "" | nindent 0 }}
    {{- else }}
      {{- printf "%s=%s" (toString $parent) (toString $section) | nindent 2 }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{- /*
  Takes a map of {filename: contents} and renders each as an ini file.

  Contents may be:
    - a raw string, rendered verbatim
    - a map of {name: value}, rendered in sorted key order. Files whose behavior
      depends on the order of their sections or entries should use the list form
    - a list, rendered in the order it was written. Each item is a map, and is
      rendered as either:
        - one record of fields followed by a blank line, when the item holds more
          than one key and none of them name a section (the shape
          /etc/rstudio/r-versions expects)
        - otherwise, one ordered entry per key: a [name] section if its value is a
          map, and a name=value line if not. Keys within an item are still sorted,
          so write one key per item to control the order
*/ -}}
{{- define "rstudio-library.config.ini" -}}
{{- range $file, $keys := . -}}
{{- printf "%s: |" $file | nindent 0 }}
{{- if kindIs "string" $keys }}
  {{- $keys | nindent 2 }}
{{- else if kindIs "slice" $keys }}
{{- range $item := $keys -}}
  {{- if not (kindIs "map" $item) }}
    {{- fail (print "\n\nEntries of '" $file "' written as a list must each be a map. Instead got '" (kindOf $item) "' : '" (print $item) "'") }}
  {{- end }}
  {{- /* A map value names a section, so an item holding one is a group of sections rather than a
         record of fields -- most often a list item that is missing its own "- ". Rendering it as
         a record would silently emit lines like "name=map[key:value]". */ -}}
  {{- $isRecord := gt (len (keys $item)) 1 }}
  {{- range $key, $val := $item }}
    {{- if kindIs "map" $val }}
      {{- $isRecord = false }}
    {{- end }}
  {{- end }}
  {{- if $isRecord }}
    {{- range $key, $val := $item }}
      {{- printf "%s=%s" (toString $key) (toString $val) | nindent 2 }}
    {{- end }}
    {{- printf "" | nindent 0 }}
  {{- else }}
    {{- range $key, $val := $item }}
      {{- include "rstudio-library.config.ini.entry" (dict (toString $key) $val) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- else }}
{{- range $parent, $child := $keys -}}
  {{- include "rstudio-library.config.ini.entry" (dict (toString $parent) $child) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "rstudio-library.config.dcf" -}}
{{- range $file, $keys := $ -}}
  {{- printf "%s: |" $file | nindent 0 }}
  {{- if kindIs "string" $keys }}
    {{- $keys | nindent 2 }}
  {{- else }}
    {{- range $parent, $child := $keys -}}
      {{- if kindIs "map" $child }}
        {{- range $key, $val := $child }}
          {{- if kindIs "map" $val }}
            {{- printf "" | nindent 0 }}
            {{- printf "%s:" (toString $key) | nindent 2 }}
            {{- range $name, $el := $val }}
              {{- printf "%s=%s" (toString $name) (toString $el) | nindent 4 }}
            {{- end }}
          {{- else }}
            {{- printf "%s: %s" (toString $key) (toString $val) | nindent 2 }}
          {{- end }}
        {{- end }}
        {{- printf "" | nindent 0 }}
      {{- else }}
        {{- printf "%s: %s" (toString $parent) (toString $child) | nindent 2 }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{ end }}

{{- define "rstudio-library.config.json" -}}
{{- range $file,$content := . }}
{{ $file }}: |
{{ $content | toPrettyJson | indent 2 }}
{{- end }}
{{- end -}}
