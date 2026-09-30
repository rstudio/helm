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
  Renders one value. ini files have no nesting, so a map has no representation, and neither does
  a list holding maps or lists. A list of single values is several values for one option, which
  files express in one of two ways, chosen by the caller through `multi`:
    join    one line, comma-joined (resource-profiles=a,b,c). The default. This is how files
            read by boost property_tree express several values, since it rejects a repeated key
    repeat  one line per value, repeating the key (www-allow-origin=a, www-allow-origin=b). This
            is how files read by boost program_options express an option that may be given more
            than once; there a comma is part of the value
    reject  fail. For files whose parser writes several values some other way that this renderer
            does not produce (pip.conf's newline-continued values, for one), so that neither of
            the above can quietly render a file the parser will refuse. The message says to
            write the file as a string
  An empty list renders nothing, whichever `multi` is in force; the caller skips it.

  Takes a dict: file, section (may be empty), key, value, multi.
*/ -}}
{{- define "rstudio-library.config.ini.value" -}}
{{- $where := .section | empty | ternary (printf "of '%s'" .file) (printf "in section [%s] of '%s'" (toString .section) .file) }}
{{- $val := .value }}
{{- if kindIs "map" $val }}
  {{- fail (print "\n\n'" (toString .key) "' " $where " is a map, but ini files have no\nnesting, so this would have rendered as '" (toString .key) "=" (toString $val) "'.\n") }}
{{- end }}
{{- if kindIs "slice" $val }}
  {{- $values := list }}
  {{- range $item := $val }}
    {{- if or (kindIs "map" $item) (kindIs "slice" $item) }}
      {{- fail (print "\n\n'" (toString $.key) "' " $where " is a list holding a " (kindOf $item) ".\nEach of an option's values must be a single value.\n") }}
    {{- end }}
    {{- $values = append $values (toString $item) }}
  {{- end }}
  {{- if eq .multi "reject" }}
    {{- fail (print "\n\n'" (toString .key) "' " $where " is a list of values, but this chart cannot write several\nvalues for one option in the way " .file " expects, so it would render a file its parser\nrefuses. Write the whole file as a string (" .file ": |), which is passed through unchanged.\n") }}
  {{- else if eq .multi "repeat" }}
    {{- $lines := list }}
    {{- range $v := $values }}
      {{- $lines = append $lines (printf "%s=%s" (toString $.key) $v) }}
    {{- end }}
    {{- join "\n" $lines }}
  {{- else }}
    {{- printf "%s=%s" (toString .key) (join "," $values) }}
  {{- end }}
{{- else }}
  {{- printf "%s=%s" (toString .key) (toString $val) }}
{{- end }}
{{- end }}

{{- /*
  Renders a single ini entry.

  Takes a dict:
    file: the file name, used in error messages
    multi: how a list of values is written; see rstudio-library.config.ini.value
    entry: a map of {name: value}, where the value is either
      - a map, which becomes a [name] section followed by its key=value pairs
      - a list of maps, which becomes repeated [name] sections (ini files may
        have more than one section with the same name)
      - anything else, which becomes a name=value line
*/ -}}
{{- define "rstudio-library.config.ini.entry" -}}
{{- $file := .file }}
{{- $multi := .multi }}
{{- range $parent, $child := .entry -}}
  {{- /* A list of maps is several sections with the same name; ini files may repeat a section.
         Any other list is several values for one option. */ -}}
  {{- $sections := list }}
  {{- if kindIs "map" $child }}
    {{- $sections = list $child }}
  {{- else if kindIs "slice" $child }}
    {{- range $item := $child }}
      {{- if kindIs "map" $item }}
        {{- $sections = append $sections $item }}
      {{- end }}
    {{- end }}
    {{- if and $sections (ne (len $sections) (len $child)) }}
      {{- fail (print "\n\n'" (toString $parent) "' of '" $file "' is a list mixing sections with plain values.\nA list of maps is repeated sections; any other list is one option's values.\n") }}
    {{- end }}
  {{- end }}
  {{- if $sections }}
    {{- range $section := $sections }}
      {{- printf "[%s]" (toString $parent) | nindent 2 }}
      {{- range $key, $val := $section }}
        {{- /* an empty list is no values, so no line */ -}}
        {{- if not (and (kindIs "slice" $val) (empty $val)) }}
          {{- include "rstudio-library.config.ini.value" (dict "file" $file "section" $parent "key" $key "value" $val "multi" $multi) | nindent 2 }}
        {{- end }}
      {{- end }}
      {{- printf "" | nindent 0 }}
    {{- end }}
  {{- else if not (and (kindIs "slice" $child) (empty $child)) }}
    {{- include "rstudio-library.config.ini.value" (dict "file" $file "section" "" "key" $parent "value" $child "multi" $multi) | nindent 2 }}
  {{- end }}
{{- end }}
{{- end }}

{{- /*
  Takes a map of {filename: contents} and renders each as an ini file, comma-joining a list of
  values. Use rstudio-library.config.ini.files to repeat the key instead.

  Contents may be:
    - a raw string, rendered verbatim
    - a map of {name: value}, rendered in sorted key order. Files whose behavior
      depends on the order of their sections or entries should use the list form
    - a list, rendered in the order it was written. Each entry is a map holding
      exactly one key: a [name] section when its value is a map, and a name=value
      line when it is not. Options within a section are still sorted, so a list
      orders its sections and entries, not the options inside them
*/ -}}
{{- define "rstudio-library.config.ini" -}}
{{- include "rstudio-library.config.ini.files" (dict "files" .) }}
{{- end }}

{{- /*
  rstudio-library.config.ini, with options. Takes a dict:
    files: a map of {filename: contents}, as rstudio-library.config.ini takes
    multi: optional. "join" (the default), "repeat" or "reject": how a list of values is written,
           at every depth. See rstudio-library.config.ini.value
*/ -}}
{{- define "rstudio-library.config.ini.files" -}}
{{- $multi := default "join" .multi }}
{{- if not (has $multi (list "join" "repeat" "reject")) }}
  {{- fail (print "\n\nrstudio-library.config.ini.files: multi must be 'join', 'repeat' or 'reject'. Instead got '" $multi "'") }}
{{- end }}
{{- range $file, $keys := .files -}}
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
    {{- fail (print "\n\n" $where " is empty. Every entry written as a list must be a map of a single name and its value.") }}
  {{- end }}
  {{- if gt (len $names) 1 }}
    {{- $hint := "" }}
    {{- range $n := $names }}
      {{- $hint = print $hint "\n    - " ($n | quote) ":\n        ..." }}
    {{- end }}
    {{- fail (print "\n\n" $where " holds more than one key: " (join ", " $names) "\n\nEach entry names one section or one value, so that they keep the order they\nwere written in. Put '- ' in front of each one:\n\n  " $file ":" $hint "\n") }}
  {{- end }}
  {{- /* Helm drops a null-valued key from a map, but a null survives inside a list, where it
         would render as "name=<nil>". */ -}}
  {{- range $name, $config := $item }}
    {{- if kindIs "invalid" $config }}
      {{- fail (print "\n\n" $where " ('" (toString $name) "') has no value. Write a section's options under it\n(- " (toString $name | quote) ": {} for an empty section), or give the entry a value\n(- " (toString $name | quote) ": \"\" for an empty one).\n") }}
    {{- end }}
  {{- end }}
  {{- include "rstudio-library.config.ini.entry" (dict "file" $file "entry" $item "multi" $multi) }}
{{- end }}
{{- else }}
{{- range $parent, $child := $keys -}}
  {{- include "rstudio-library.config.ini.entry" (dict "file" $file "entry" (dict (toString $parent) $child) "multi" $multi) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- /*
  Takes a map of {filename: contents} and renders each as a DCF file: `Key: Value` lines, with a
  blank line between records. Contents may be a raw string (verbatim), a map of fields (one
  record, or one record per map-valued key), or a list of maps (one record per entry, in the
  order written).
*/ -}}
{{- define "rstudio-library.config.dcf" -}}
{{- range $file, $keys := $ -}}
  {{- printf "%s: |" $file | nindent 0 }}
  {{- if kindIs "string" $keys }}
    {{- $keys | nindent 2 }}
  {{- else }}
    {{- range $parent, $child := $keys -}}
      {{- if and (kindIs "slice" $keys) (not (kindIs "map" $child)) }}
        {{- fail (print "\n\nentry " (add $parent 1) " of '" $file "' must be a map of fields (Key: Value), which is one DCF record.\nInstead got '" (kindOf $child) "' : '" (print $child) "'") }}
      {{- end }}
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
