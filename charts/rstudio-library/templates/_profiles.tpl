{{/*
  Read the job-json-overrides configuration and build the JSON files on disk to support them
    Looks at the "json" key of the job-json-overrides definition

  Takes a dict:
    data: the launcher.kubernetes.profiles.conf configuration as a dict (map of maps)
    default: optional. The default job-json-overrides to append

  - Build a unique list of overrides (and a unique list of names for testing uniqueness)
  - Iterate over the list to build a json file dict
  - delegate to rstudio-library.config.json for building the json files

  NOTE: presumes that the default config is a unique list already
*/}}
{{- define "rstudio-library.profiles.json-from-overrides-config" -}}
  {{- $allOverrides := default (list) .default -}}
  {{- if $allOverrides }}
    {{- $allOverrides = $allOverrides | deepCopy }}
  {{- end }}
  {{- include "rstudio-library.debug.type-check" (dict "name" "profiles defaults" "object" $allOverrides "expected" "slice" "description" "of jobJsonOverrides defaults") }}
  {{- $allOverridesNames := list -}}
  {{- /* Start the unique list of names from the names in .default */ -}}
  {{- range $item := $allOverrides -}}
    {{- if not ( has $item.name $allOverridesNames ) -}}
      {{- $allOverridesNames := append $allOverridesNames $item.name -}}
    {{- end -}}
  {{- end -}}
  {{- /* Build a unique list of overrides and names from all config sections */ -}}
  {{- $data := .data }}
  {{- if $data }}
    {{- $data = $data | deepCopy }}
  {{- end }}
  {{- if not (kindIs "slice" $data) }}
    {{- include "rstudio-library.debug.type-check" (dict "name" "config data" "object" $data "expected" "map" "description" "of section headers and configuration" ) }}
  {{- end }}
  {{- $sections := dict }}
  {{- include "rstudio-library.profiles.sections" (dict "file" "" "data" $data "out" $sections) }}
  {{- range $s := $sections.sections -}}
    {{- $config := $s.section }}
    {{- if hasKey $config "job-json-overrides" -}}
      {{- $overrides := get $config "job-json-overrides" -}}
      {{- include "rstudio-library.debug.type-check" (dict "name" "[*].job-json-overrides" "object" $overrides "expected" "slice" "description" "of job-json-overrides definitions") }}
      {{ range $override := $overrides -}}
        {{- if not (has $override.name $allOverridesNames ) -}}
          {{- $allOverrides = append $allOverrides $override -}}
          {{- $allOverridesNames = append $allOverridesNames $override.name -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- /* Build a json configuration dict (to be passed to rstudio-library.config.json) */ -}}
  {{- $jsonConfig := dict -}}
  {{- range $override := $allOverrides -}}
    {{- if not ( and ( and (hasKey $override "name") (hasKey $override "json") ) (hasKey $override "target") ) -}}
      {{- fail ( print "\n\nJobJsonOverride: '" $override "' must have keys 'name', 'json', and 'target'" ) -}}
    {{- end -}}
    {{- $fileName := print ($override.name | nospace) ".json" -}}
    {{- $contents := $override.json -}}
    {{- $partialDict := dict $fileName $contents -}}
    {{- $jsonConfig := mergeOverwrite $jsonConfig $partialDict -}}
  {{- end -}}
  {{- include "rstudio-library.config.json" $jsonConfig -}}
{{- end -}}

{{/*
  Collapse an array via the following rule:
    - if an array with simple values, collapse with commas
      i.e. [one,two,three] => one,two,three
    - if an array with "target" and "file" keys, collapse with quotes, commas and colons
      i.e. [{target:one, file:two}, {target:three, file:four}] =>
        "one":"two","three":"four"
*/}}
{{- define "rstudio-library.profiles.ini.collapse-array" -}}
{{- range $i, $arrEntry := . }}
{{- if kindIs "map" $arrEntry }}
{{- if ge $i 1 }}
{{- print "," }}
{{- end }}
{{- if and (hasKey $arrEntry "target") (hasKey $arrEntry "file") }}
{{- $arrEntry.target | quote }}:{{ $arrEntry.file | quote }}
{{- end }}
{{- else }}
{{- if ge $i 1 }}
{{- print "," }}
{{- end }}
{{- $arrEntry }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
  Builds a single profiles configuration file by:
    - Concat "everyone" job-json-overrides (at .data.*.job-json-overrides) to .default
    - Loop through the other sections and:
      - prepend "default config" to any user / group job-json-overrides
    - Set the result on a copy of .data, adding a [*] section (at the top, for the list form) if
      there is none
    - output the ini file

  The file may be a map of sections, or a list of single-key maps to keep their order (see
  rstudio-library.config.ini). [*] may appear only once, and must be a single map.

  Takes a dict:
    data: the launcher.kubernetes.profiles.conf configuration as a map of maps, or a list
    default: optional. the default job-json-overrides to append
    filePath: optional. the default is none
    file: optional. the file name, used in error messages
*/}}
{{- define "rstudio-library.profiles.apply-everyone-and-default-to-others" }}
  {{- $file := default "" .file }}
  {{- $data := .data }}
  {{- if $data }}
    {{- $data = $data | deepCopy }}
  {{- else }}
    {{- $data = dict }}
  {{- end }}
  {{- $s := dict }}
  {{- include "rstudio-library.profiles.sections" (dict "file" $file "data" $data "out" $s) }}
  {{- $everyoneConfig := dict }}
  {{- if $s.hasEveryone }}
    {{- $everyoneConfig = $s.everyone }}
  {{- end }}
  {{- $defaultConfig := default (list) .default }}
  {{- if $defaultConfig }}
    {{- $defaultConfig = $defaultConfig | deepCopy }}
  {{- end }}
  {{- include "rstudio-library.debug.type-check" (dict "name" "profiles defaults" "object" $defaultConfig "expected" "slice" "description" "of jobJsonOverrides defaults") }}
  {{- $filePath := default "" .filePath }}
  {{- /* Create a "file" key from the "name" key */ -}}
  {{- range $entry := $defaultConfig }}
    {{- $_ := set $entry "file" ( print $filePath ($entry.name | nospace) ".json" ) }}
  {{- end }}
  {{- /* modify the defaultConfig value if "everyone" is defined (under "*"), by appending the everyone config to default */ -}}
  {{- if hasKey $everyoneConfig "job-json-overrides" }}
    {{- $everyone := get $everyoneConfig "job-json-overrides" }}
    {{- include "rstudio-library.debug.type-check" (dict "name" "[*].job-json-overrides" "object" $everyone "expected" "slice" "description" "of job-json-overrides definitions") }}
    {{- range $entry := $everyone }}
      {{- $_ := set $entry "file" ( print $filePath ($entry.name | nospace) ".json" ) }}
    {{- end }}
    {{- $defaultConfig = concat $defaultConfig $everyone }}
  {{- end }}
  {{- /* loop over non-everyone sections, prepending the default configuration */ -}}
  {{- range $section := $s.sections }}
    {{- $one := $section.section }}
    {{- if and (ne (toString $section.name) "*") (hasKey $one "job-json-overrides") }}
      {{- $oneConfig := get $one "job-json-overrides" }}
      {{- include "rstudio-library.debug.type-check" (dict "name" ( print "[" $section.name "].job-json-overrides" ) "object" $oneConfig "expected" "slice" "description" "of job-json-overrides definitions") }}
      {{- range $entry := $oneConfig }}
        {{- $_ := set $entry "file" ( print $filePath ($entry.name | nospace) ".json" ) }}
      {{- end }}
      {{- $_ := set $one "job-json-overrides" (concat $defaultConfig $oneConfig) }}
    {{- end }}
  {{- end }}
  {{- /* if default config is defined, ensure that "everyone" is updated by it */ -}}
  {{- if ge (len $defaultConfig) 1 }}
    {{- if $s.hasEveryone }}
      {{- $_ := set $everyoneConfig "job-json-overrides" $defaultConfig }}
    {{- else if kindIs "slice" $data }}
      {{- $data = prepend $data (dict "*" (dict "job-json-overrides" $defaultConfig)) }}
    {{- else }}
      {{- $_ := set $data "*" (dict "job-json-overrides" $defaultConfig) }}
    {{- end }}
  {{- end }}
  {{- /* output the configuration file */ -}}
  {{- include "rstudio-library.profiles.ini.render" (dict "file" $file "data" $data) }}
{{- end }}

{{- /*
  Lists the sections of a profiles file, checking the rules that the profiles helpers rely on:
  [*] appears at most once and is a single map, and every other entry is a section (a map, or a
  list of maps). Sets on .out:
    .out.sections: as in rstudio-library.config.ini.entries
    .out.hasEveryone: whether there is a [*] section
    .out.everyone: the [*] section map, from .data (not a copy)

  Takes a dict:
    file: the file name, used in error messages
    data: a map of sections, or a list of single-key maps
    out: a dict to receive the results
*/ -}}
{{- define "rstudio-library.profiles.sections" -}}
{{- $file := .file }}
{{- $out := .out }}
{{- include "rstudio-library.config.ini.entries" (dict "file" $file "content" .data "out" $out) }}
{{- $count := 0 }}
{{- range $entry := $out.entries }}
  {{- if eq (toString $entry.name) "*" }}
    {{- $count = add1 $count }}
    {{- if gt $count 1 }}
      {{- fail (printf "\n\nprofiles file '%s': the [*] section appears more than once. The chart merges its defaults into [*] and adds [*]'s job-json-overrides to the other sections, so [*] must be a single section. Combine the [*] entries into one." $file) }}
    {{- end }}
    {{- if kindIs "slice" $entry.value }}
      {{- fail (printf "\n\nprofiles file '%s': [*] is a list, which would render several [*] sections. The chart merges its defaults into [*] and adds [*]'s job-json-overrides to the other sections, so [*] must be a single map of options." $file) }}
    {{- end }}
    {{- include "rstudio-library.debug.type-check" (dict "name" "[*] section" "object" $entry.value "expected" "map" "description" "of config values") }}
    {{- $_ := set $out "everyone" $entry.value }}
  {{- else if kindIs "slice" $entry.value }}
    {{- range $item := $entry.value }}
      {{- include "rstudio-library.debug.type-check" (dict "name" (print "[" $entry.name "] section" ) "object" $item "expected" "map" "description" "of config values") }}
    {{- end }}
  {{- else }}
    {{- include "rstudio-library.debug.type-check" (dict "name" (print "[" $entry.name "] section" ) "object" $entry.value "expected" "map" "description" "of config values") }}
  {{- end }}
{{- end }}
{{- $_ := set $out "hasEveryone" (eq $count 1) }}
{{- end }}

{{- /*
  Renders a profiles file with rstudio-library.config.ini.file, after turning each
  job-json-overrides list into its "target":"file" string (see
  rstudio-library.profiles.ini.collapse-array). Modifies .data.

  Takes a dict:
    file: the file name, used in error messages
    data: a map of sections, or a list of single-key maps
*/ -}}
{{- define "rstudio-library.profiles.ini.render" -}}
{{- $s := dict }}
{{- include "rstudio-library.config.ini.entries" (dict "file" .file "content" .data "out" $s) }}
{{- range $section := $s.sections }}
  {{- $overrides := get $section.section "job-json-overrides" }}
  {{- if kindIs "slice" $overrides }}
    {{- $_ := set $section.section "job-json-overrides" (include "rstudio-library.profiles.ini.collapse-array" $overrides) }}
  {{- end }}
{{- end }}
{{- include "rstudio-library.config.ini.file" (dict "file" .file "content" .data) }}
{{- end }}

{{/*
  Builds a single profiles ini file with rstudio-library.config.ini.file, after collapsing
  job-json-overrides via rstudio-library.profiles.ini.collapse-array
*/}}
{{- define "rstudio-library.profiles.ini.singleFile" -}}
{{- $data := . }}
{{- if $data }}
  {{- $data = $data | deepCopy }}
{{- end }}
{{- include "rstudio-library.profiles.ini.render" (dict "file" "" "data" $data) }}
{{- end }}

{{- /*
  Builds many profiles ini files
  Drop in replacement for rstudio-library.config.ini
    (except behaves in ways that are custom to profiles)
*/ -}}
{{- define "rstudio-library.profiles.ini" -}}
{{- range $file, $keys := . -}}
{{- printf "%s: |" $file | nindent 0 }}
{{- $data := $keys }}
{{- if $data }}
  {{- $data = $data | deepCopy }}
{{- end }}
{{- include "rstudio-library.profiles.ini.render" (dict "file" $file "data" $data) }}
{{- end }}
{{- end }}

{{/*
  Takes a dict:
    - .data : a map of file names to their configuration: a map of sections, or a list of
      single-key maps to keep their order
    - .jobJsonDefaults : an array of {target:target, name:name, json:json} defaults
    - .filePath : the path from the root of the system to where json overrides files will be mounted
*/}}
{{- define "rstudio-library.profiles.ini.advanced" -}}
{{- $jobJsonDefaults := default (list) .jobJsonDefaults }}
{{- include "rstudio-library.debug.type-check" (dict "name" "profiles jobJsonDefaults" "object" $jobJsonDefaults "expected" "slice" "description" "of jobJsonOverrides defaults") }}
{{- $filePath := default "" .filePath }}
{{- $data := .data }}
{{- include "rstudio-library.debug.type-check" (dict "name" "profiles data" "object" $data "expected" "map" "description" "of filenames and config data") }}
{{- range $file, $keys := $data -}}
{{- if not (kindIs "slice" $keys) }}
  {{- include "rstudio-library.debug.type-check" (dict "name" (print "profiles content for file '" $file "'") "object" $keys "expected" "map" "description" "of section headers and configuration") }}
{{- end }}
{{- printf "%s: |" $file | nindent 0 }}
{{- include "rstudio-library.profiles.apply-everyone-and-default-to-others" (dict "data" $keys "default" $jobJsonDefaults "filePath" $filePath "file" $file) }}
{{- end }}
{{- end }}
