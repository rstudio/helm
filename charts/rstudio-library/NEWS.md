# 0.1.11

- Fix whitespace issue in `.ini` for arrays

# 0.1.10

- Fix a bug in `.dcf` and `.ini` file config that did not convert non-strings (i.e. bool, float64, etc.) to strings
  properly

# 0.1.9

- Make rstudio-library.config.ini handle plaintext values
- Make rstudio-library.config.dcf handle plaintext values
- Add testing for .ini and .dcf config files

# 0.1.8

- Add more json validation for cleaner error messaging
- Add a "debug" helper for type validation

# 0.1.7

- Allow separating `targetNamespace` from `namespace` for RBAC definition
  - In a future state, we might allow multiple namespaces... but we have not taken that on yet,
  because launcher does not support multiple namespaces yet

# 0.1.6

- Fix a few bugs in defaults ordering
- Add `deepCopy` to some of the more complex `profiles` helpers
  - This is important so that our modifications of objects do not surface to users of the chart
  - (i.e. this ensures they avoid weird edge cases and using `deepCopy` themselves)

# 0.1.5

- Fix a bug in empty profiles

# 0.1.4

- Add a bunch of profiles helpers

# 0.1.1

- Specify namespace in ClusterRoleBinding always (it is required)
  - This is unfortunate, because it makes our output YAML less portable

# 0.1.0

- Initial release
- Add RBAC, config helpers
