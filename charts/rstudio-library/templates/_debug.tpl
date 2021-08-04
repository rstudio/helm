{{/*
  Checks type and prints an informative error message

  Takes a dict:
    name: the description of what it is
    object: the object to type check
    expected: the expected type
    description: additional description of the "expected" type. Optional
*/}}
{{- define "rstudio-library.debug.type-check" }}
{{- $expectedDescription := (.description | default "") }}
{{- if $expectedDescription }}
  {{- $expectedDescription = print " " $expectedDescription }}
{{- end }}
{{- if not (kindIs .expected .object) }}
  {{- fail (print "\n\n" .name " must be a '" .expected "'" $expectedDescription ". Instead got '" (kindOf .object) "' : '" (print .object) "'" ) }}
{{- end }}
{{- end }}
