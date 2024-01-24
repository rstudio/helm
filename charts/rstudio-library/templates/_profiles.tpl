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
  {{- include "rstudio-library.debug.type-check" (dict "name" "config data" "object" $data "expected" "map" "description" "of section headers and configuration" ) }}
  {{- range $key, $config := $data -}}
    {{- include "rstudio-library.debug.type-check" (dict "name" (print "[" $key "] section") "object" $config "expected" "map" "description" "of config data" ) }}
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
    - Loop through other parent keys and:
      - prend "default config" to any user / group definitions
    - Take the "override dict" that is created here, and mergeOverwrite with the provided .data
    - output the ini file

  Takes a dict:
    data: the launcher.kubernetes.profiles.conf configuration as a dict (map of maps)
    default: optional. the default job-json-overrides to append
    filePath: optional. the default is none
*/}}
{{- define "rstudio-library.profiles.apply-everyone-and-default-to-others" }}
  {{- $newDict := dict }}
  {{- $everyoneConfig := dict }}
  {{- $data := .data }}
  {{- if $data }}
    {{- $data = $data | deepCopy }}
  {{- end }}
  {{- if hasKey $data "*" }}
    {{- $everyoneConfig = get $data "*" }}
  {{- end }}
  {{- include "rstudio-library.debug.type-check" (dict "name" "[*] section" "object" $everyoneConfig "expected" "map" "description" "of config values") }}
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
  {{- /* if default config is defined, ensure that "everyone" is updated by it */ -}}
  {{- if ge (len $defaultConfig) 1 }}
    {{- $newDict = mergeOverwrite $newDict (dict "*" (dict "job-json-overrides" $defaultConfig)) }}
  {{- end }}
  {{- /* loop over non-everyone config, prepending the default configuration */ -}}
  {{- $others := omit $data "*" }}
  {{- range $key, $one := $others }}
    {{- include "rstudio-library.debug.type-check" (dict "name" (print "[" $key "] section" ) "object" $one "expected" "map" "description" "of config values") }}
    {{- if hasKey $one "job-json-overrides" }}
      {{- $oneConfig := get $one "job-json-overrides" }}
      {{- include "rstudio-library.debug.type-check" (dict "name" ( print "[" $key "].job-json-overrides" ) "object" $oneConfig "expected" "slice" "description" "of job-json-overrides definitions") }}
      {{- range $entry := $oneConfig }}
        {{- $_ := set $entry "file" ( print $filePath ($entry.name | nospace) ".json" ) }}
      {{- end }}
      {{- $oneList := concat $defaultConfig $oneConfig }}
      {{- $oneDict := dict $key (dict "job-json-overrides" $oneList) }}
      {{- $newDict = mergeOverwrite $newDict $oneDict }}
    {{- end }}
  {{- end }}
  {{- /* output the configuration file */ -}}
  {{- $output := mergeOverwrite $data $newDict }}
  {{- include "rstudio-library.profiles.ini.singleFile" $output }}
{{- end }}

{{/*
  Builds a single ini file
  Modified from rstudio-library.config.ini to:
    - collapse arrays
    - via rstudio-library.profiles.ini.collapse-array
*/}}
{{- define "rstudio-library.profiles.ini.singleFile" -}}
{{- range $parent, $child := . -}}
  {{- if kindIs "map" $child }}

  {{ if not ( kindIs "slice" . ) -}}
  [{{ $parent }}]
  {{- end }}
  {{- range $key, $val := $child }}
  {{- if kindIs "slice" $val }}
  {{ $key }}={{ include "rstudio-library.profiles.ini.collapse-array" $val }}
  {{- else }}
  {{ $key }}={{ $val }}
  {{- end }}
  {{- end }}
  {{- else }}
  {{ $parent }}={{ $child }}
  {{- end }}
{{- end }}
{{- end }}

{{- /*
  Builds many profiles ini files
  Drop in replacement for rstudio-library.config.ini
    (except behaves in ways that are custom to profiles)
*/ -}}
{{- define "rstudio-library.profiles.ini" -}}
{{- range $file, $keys := . -}}
{{ $file }}: |
{{- include "rstudio-library.profiles.ini.singleFile" $keys }}

{{ end }}
{{ end }}

{{/*
  Takes a dict:
    - .data : the configuration map of maps
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
{{- include "rstudio-library.debug.type-check" (dict "name" (print "profiles content for file '" $file "'") "object" $keys "expected" "map" "description" "of section headers and configuration") }}
{{ $file }}: |
{{- include "rstudio-library.profiles.apply-everyone-and-default-to-others" (dict "data" $keys "default" $jobJsonDefaults "filePath" $filePath) }}

{{ end }}
{{- end }}
