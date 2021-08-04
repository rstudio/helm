{{- define "rstudio-library.test.overwrite" }}
{{- $default := dict
  "key3" (dict "child" "value")
  "key2" (dict "child" "value")
  "arr" (dict "child" (list 1 2 3))
}}
{{- $overwrite := dict
  "key" (dict "child" "new")
  "arr" (dict "child" (list 4 5 6))
}}
{{- $output := mergeOverwrite $default $overwrite }}
{{ print $output }}
{{- end }}


{{- define "rstudio-library.test.listUnique" }}
{{- $myList := list (dict "one" "two") (dict "one" "two") (dict "three" "four") }}
{{- print $myList }}
{{- end }}
