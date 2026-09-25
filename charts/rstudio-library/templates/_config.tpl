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
      {{- fail (print "\n\nEvery entry written as a list must be a map of a single name and its value. Instead got '" (kindOf $item) "' : '" (print $item) "'") }}
    {{- end }}
    {{- $names := keys $item | sortAlpha }}
    {{- if ne (len $names) 1 }}
      {{- $hint := "" }}
      {{- range $n := $names }}
        {{- $hint = print $hint "\n  - " ($n | quote) ":\n      ..." }}
      {{- end }}
      {{- fail (print "\n\nAn entry written as a list holds " (len $names) " keys: " (join ", " $names) "\n\nEach entry names one section, so that the sections keep the order they were\nwritten in. Put '- ' in front of each one:\n" $hint "\n") }}
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
  Renders a single ini entry.

  Takes a dict:
    file: the file name, used in error messages
    entry: a map of {name: value}, where the value is either
      - a map, which becomes a [name] section followed by its key=value pairs
      - a list of maps, which becomes repeated [name] sections (ini files may
        have more than one section with the same name)
      - anything else, which becomes a bare name=value line

  An option inside a section must be a single value. ini has no nesting, so a map
  or a list there has no representation and used to render as "key=map[a:1]" or
  "key=[a b]". (rstudio-library.profiles.ini does define a meaning for a list --
  it comma-joins -- which is why it does not share this helper.)
*/ -}}
{{- define "rstudio-library.config.ini.entry" -}}
{{- $file := .file }}
{{- range $parent, $child := .entry -}}
  {{- $sections := ( (kindIs "slice" $child) | ternary $child ( list $child ))}}
  {{- range $i, $section := $sections -}}
    {{- if kindIs "map" $section }}
      {{- printf "[%s]" (toString $parent) | nindent 2 }}
      {{- range $key, $val := $section }}
        {{- if or (kindIs "map" $val) (kindIs "slice" $val) }}
          {{- $kind := (kindIs "map" $val) | ternary "a map" "a list" }}
          {{- $fix := (kindIs "map" $val) | ternary "" "\n\nIf the file expects several values, write them as one value, such as \"a,b\"." }}
          {{- fail (print "\n\n'" (toString $key) "' in section [" (toString $parent) "] of '" $file "' is " $kind ", but an option\ninside a section must be a single value. ini files have no nesting, so this\nwould have rendered as '" (toString $key) "=" (toString $val) "'." $fix "\n") }}
        {{- end }}
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
    - a list, rendered in the order it was written. Each entry is a non-empty map:
        - a key whose value is a map names a section, and must be the only key in
          its entry, so that sections keep the order they were written in
        - otherwise the entry is a record of fields, rendered as name=value lines
          followed by a blank line (the shape /etc/rstudio/r-versions expects)
      Keys within one entry are sorted, so the order of a list is the order of its
      sections and entries, not of the options inside them
*/ -}}
{{- define "rstudio-library.config.ini" -}}
{{- range $file, $keys := . -}}
{{- printf "%s: |" $file | nindent 0 }}
{{- if kindIs "string" $keys }}
  {{- $keys | nindent 2 }}
{{- else if kindIs "slice" $keys }}
{{- range $i, $item := $keys -}}
  {{- $where := print "entry " (add $i 1) " of '" $file "'" }}
  {{- if not (kindIs "map" $item) }}
    {{- fail (print "\n\n" $where " must be a map of a name and its value. Instead got '" (kindOf $item) "' : '" (print $item) "'") }}
  {{- end }}
  {{- $names := keys $item | sortAlpha }}
  {{- if eq (len $names) 0 }}
    {{- fail (print "\n\n" $where " is empty. Every entry written as a list must be a map of a name and its value.") }}
  {{- end }}
  {{- /* A map value names a section, so it has to be the only key in its entry. Otherwise the
         sections in one entry would be sorted against each other, losing the order the list is
         there to preserve -- and before this check, they rendered as "name=map[key:value]".
         Almost always a list entry that is missing its own "- ". */ -}}
  {{- $sections := list }}
  {{- range $key, $val := $item }}
    {{- if kindIs "map" $val }}
      {{- $sections = append $sections (toString $key) }}
    {{- end }}
  {{- end }}
  {{- if and $sections (gt (len $names) 1) }}
    {{- $hint := "" }}
    {{- range $s := $sections }}
      {{- $hint = print $hint "\n    - " ($s | quote) ":\n        ..." }}
    {{- end }}
    {{- fail (print "\n\n" $where " holds more than one key: " (join ", " $names) "\n\nA key whose value is a section must be the only key in its entry, so that the\nsections keep the order they were written in. These name sections: " (join ", " $sections) "\n\nPut '- ' in front of each one:\n\n  " $file ":" $hint "\n") }}
  {{- end }}
  {{- if gt (len $names) 1 }}
    {{- /* a record of fields, the shape /etc/rstudio/r-versions expects */ -}}
    {{- range $key, $val := $item }}
      {{- printf "%s=%s" (toString $key) (toString $val) | nindent 2 }}
    {{- end }}
    {{- printf "" | nindent 0 }}
  {{- else }}
    {{- include "rstudio-library.config.ini.entry" (dict "file" $file "entry" $item) }}
  {{- end }}
{{- end }}
{{- else }}
{{- range $parent, $child := $keys -}}
  {{- include "rstudio-library.config.ini.entry" (dict "file" $file "entry" (dict (toString $parent) $child)) }}
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
