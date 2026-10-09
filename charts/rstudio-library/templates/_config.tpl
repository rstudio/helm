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
  Takes a map of ini files, keyed by file name. Each file is one of:
    - a string, used as the whole file;
    - a map of entries, rendered in sorted order;
    - a list of single-key maps ("list form"), rendered in the order written.

  An entry whose value is a map is a [section]. A list of maps repeats the section, once per
  map. A list of plain values repeats the key, once per value. Any other value is a key=value
  line. Inside a section, a list of plain values is written comma-separated.
*/ -}}
{{- define "rstudio-library.config.ini" -}}
{{- range $file, $content := . -}}
{{- printf "%s: |" $file | nindent 0 }}
{{- include "rstudio-library.config.ini.file" (dict "file" $file "content" $content) }}
{{- end }}
{{- end }}

{{- /*
  Renders the content of a single ini file, indented by two spaces

  Takes a dict:
    file: the file name, used in error messages
    content: a string, a map of entries, or a list of single-key maps (see config.ini)
*/ -}}
{{- define "rstudio-library.config.ini.file" -}}
{{- $file := .file }}
{{- if kindIs "string" .content }}
  {{- .content | nindent 2 }}
{{- else }}
  {{- $out := dict }}
  {{- include "rstudio-library.config.ini.entries" (dict "file" $file "content" .content "out" $out) }}
  {{- range $entry := $out.entries }}
    {{- $name := $entry.name }}
    {{- $value := $entry.value }}
    {{- if kindIs "map" $value }}
      {{- include "rstudio-library.config.ini.section" (dict "file" $file "name" $name "section" $value) }}
    {{- else if kindIs "slice" $value }}
      {{- $maps := 0 }}
      {{- $plain := 0 }}
      {{- range $item := $value }}
        {{- if kindIs "map" $item }}
          {{- $maps = add1 $maps }}
        {{- else if not (kindIs "slice" $item) }}
          {{- $plain = add1 $plain }}
        {{- end }}
      {{- end }}
      {{- if eq $maps (len $value) }}
        {{- range $section := $value }}
          {{- include "rstudio-library.config.ini.section" (dict "file" $file "name" $name "section" $section) }}
        {{- end }}
      {{- else if eq $plain (len $value) }}
        {{- range $item := $value }}
          {{- printf "%s=%s" (toString $name) (toString $item) | nindent 2 }}
        {{- end }}
      {{- else }}
        {{- fail (printf "\n\nini file '%s': '%s' is a list that mixes maps, lists and plain values. A list of maps repeats the [%s] section, once per map; a list of plain values repeats the key, once per value. ini has no way to write anything else." $file $name $name) }}
      {{- end }}
    {{- else }}
      {{- printf "%s=%s" (toString $name) (toString $value) | nindent 2 }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{- /*
  Renders one [section] of an ini file. Options are sorted; a list of plain values is written
  comma-separated.

  Takes a dict:
    file: the file name, used in error messages
    name: the section name
    section: a map of options
*/ -}}
{{- define "rstudio-library.config.ini.section" -}}
{{- $file := .file }}
{{- $name := .name }}
{{- printf "[%s]" (toString $name) | nindent 2 }}
{{- range $key, $val := .section }}
  {{- if kindIs "map" $val }}
    {{- fail (printf "\n\nini file '%s': option '%s' in section [%s] is a map. ini can't nest maps inside a section; give the option a single value, or a list of values (written comma-separated)." $file $key $name) }}
  {{- else if kindIs "slice" $val }}
    {{- range $item := $val }}
      {{- if or (kindIs "map" $item) (kindIs "slice" $item) }}
        {{- fail (printf "\n\nini file '%s': option '%s' in section [%s] is a list that contains a %s. Inside a section, a list can only hold plain values, which are written comma-separated." $file $key $name (kindOf $item)) }}
      {{- end }}
    {{- end }}
    {{- printf "%s=%s" (toString $key) (join "," $val) | nindent 2 }}
  {{- else }}
    {{- printf "%s=%s" (toString $key) (toString $val) | nindent 2 }}
  {{- end }}
{{- end }}
{{- printf "" | nindent 0 }}
{{- end }}

{{- /*
  Lists the entries of an ini file in the order they are rendered, checking the shape of the list
  form. Template helpers can't return values, so the results are set on .out:
    .out.entries: a list of dicts {name, value}, one per entry
    .out.sections: a list of dicts {name, section}, one per [section] the file renders. A list of
      maps contributes one per map. The section maps are the ones in .content, not copies.

  Takes a dict:
    file: the file name, used in error messages
    content: a map of entries, a list of single-key maps, or nil
    out: a dict to receive the results
*/ -}}
{{- define "rstudio-library.config.ini.entries" -}}
{{- $file := .file }}
{{- $content := .content }}
{{- $entries := list }}
{{- if kindIs "map" $content }}
  {{- range $name, $value := $content }}
    {{- $entries = append $entries (dict "name" $name "value" $value) }}
  {{- end }}
{{- else if kindIs "slice" $content }}
  {{- range $i, $entry := $content }}
    {{- $n := add1 $i }}
    {{- if not (kindIs "map" $entry) }}
      {{- fail (printf "\n\nini file '%s': list entry %d is '%v', not a map. When a file is written as a list, each entry is a single section or option:\n\n  - section-name:\n      option: value\n  - option-name: value" $file $n $entry) }}
    {{- end }}
    {{- if eq (len $entry) 0 }}
      {{- fail (printf "\n\nini file '%s': list entry %d is empty. Each entry needs exactly one key: a section name with its options, or an option name with its value." $file $n) }}
    {{- end }}
    {{- if gt (len $entry) 1 }}
      {{- fail (printf "\n\nini file '%s': list entry %d has more than one key (%s). Each entry needs exactly one key; this usually means a missing '- ' or indentation that puts an option at the level of the section name:\n\n  - section-name:\n      option: value" $file $n (keys $entry | sortAlpha | join ", ")) }}
    {{- end }}
    {{- $name := keys $entry | first }}
    {{- $value := get $entry $name }}
    {{- if kindIs "invalid" $value }}
      {{- fail (printf "\n\nini file '%s': list entry %d ('%s') has no value. Put the section's options under it, indented past the name:\n\n  - %s:\n      option: value" $file $n $name (quote $name)) }}
    {{- end }}
    {{- $entries = append $entries (dict "name" $name "value" $value) }}
  {{- end }}
{{- else if not (kindIs "invalid" $content) }}
  {{- fail (printf "\n\nini file '%s' is a %s ('%v'). Write it as a map of sections and options, as a list of single-key maps to keep their order, or as a string used as the whole file." $file (kindOf $content) $content) }}
{{- end }}
{{- $sections := list }}
{{- range $entry := $entries }}
  {{- if kindIs "map" $entry.value }}
    {{- $sections = append $sections (dict "name" $entry.name "section" $entry.value) }}
  {{- else if kindIs "slice" $entry.value }}
    {{- range $item := $entry.value }}
      {{- if kindIs "map" $item }}
        {{- $sections = append $sections (dict "name" $entry.name "section" $item) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $_ := set .out "entries" $entries }}
{{- $_ := set .out "sections" $sections }}
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
