

# rstudio-library-test

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Test harness for rstudio-library templates

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../../charts/rstudio-library | rstudio-library | 0.1.35 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| testChronicle.enabled | bool | `true` |  |
| testChronicle.image.registry | string | `"ghcr.io"` |  |
| testChronicle.image.repository | string | `"rstudio/chronicle-agent"` |  |
| testChronicle.image.tag | string | `"1.0.0"` |  |
| testChronicle.serverAddress | string | `"http://chronicle-server.default:8080"` |  |
| testChronicle.serverNamespace | string | `""` |  |
| testConfig.dcf.config.key1 | string | `"value1"` |  |
| testConfig.dcf.config.nested.subkey | string | `"subvalue"` |  |
| testConfig.dcf.filename | string | `"test.dcf"` |  |
| testConfig.gcfg.config.section1.key1 | string | `"value1"` |  |
| testConfig.gcfg.config.section1.key2 | string | `"value2"` |  |
| testConfig.gcfg.config.section2.arrayKey[0] | string | `"item1"` |  |
| testConfig.gcfg.config.section2.arrayKey[1] | string | `"item2"` |  |
| testConfig.gcfg.filename | string | `"test.gcfg"` |  |
| testConfig.ini.config.section1.key1 | string | `"value1"` |  |
| testConfig.ini.config.section1.key2 | int | `123` |  |
| testConfig.ini.filename | string | `"test.ini"` |  |
| testConfig.json.config.arrayKey[0] | string | `"item1"` |  |
| testConfig.json.config.arrayKey[1] | string | `"item2"` |  |
| testConfig.json.config.boolKey | bool | `true` |  |
| testConfig.json.config.numberKey | int | `42` |  |
| testConfig.json.config.stringKey | string | `"stringValue"` |  |
| testConfig.json.filename | string | `"test.json"` |  |
| testConfig.txt.config.key1 | string | `"value1"` |  |
| testConfig.txt.config.key2 | string | `"value2"` |  |
| testConfig.txt.filename | string | `"test.txt"` |  |
| testDebug.boolValue | bool | `true` |  |
| testDebug.mapValue.key | string | `"value"` |  |
| testDebug.sliceValue[0] | string | `"item1"` |  |
| testDebug.sliceValue[1] | string | `"item2"` |  |
| testDebug.stringValue | string | `"test string"` |  |
| testIngress.path | string | `"/test"` |  |
| testIngress.pathType | string | `"Prefix"` |  |
| testIngress.serviceName | string | `"test-service"` |  |
| testIngress.servicePort | int | `8080` |  |
| testLauncherTemplates.content.key1 | string | `"value1"` |  |
| testLauncherTemplates.content.key2 | string | `"value2"` |  |
| testLauncherTemplates.content.nested.subkey | string | `"subvalue"` |  |
| testLauncherTemplates.templateName | string | `"test-template"` |  |
| testLicense.licenseFile | string | `"LICENSE CONTENT HERE\n"` |  |
| testLicense.licenseKey | string | `"test-license-key"` |  |
| testLicense.licenseServer | string | `"license.example.com"` |  |
| testProfiles.advanced.data."launcher.kubernetes.profiles.conf".*.default-cpus | int | `1` |  |
| testProfiles.advanced.data."launcher.kubernetes.profiles.conf".testuser.default-cpus | int | `4` |  |
| testProfiles.advanced.filePath | string | `"/etc/rstudio/"` |  |
| testProfiles.advanced.jobJsonDefaults | list | `[]` |  |
| testProfiles.basicIni."launcher.kubernetes.profiles.conf".*.default-cpus | int | `1` |  |
| testProfiles.basicIni."launcher.kubernetes.profiles.conf".*.default-mem-mb | int | `512` |  |
| testProfiles.basicIni."launcher.kubernetes.profiles.conf".testuser.default-cpus | int | `2` |  |
| testProfiles.collapseArray.simple[0] | string | `"one"` |  |
| testProfiles.collapseArray.simple[1] | string | `"two"` |  |
| testProfiles.collapseArray.simple[2] | string | `"three"` |  |
| testProfiles.collapseArray.targetFile[0].file | string | `"/etc/config/pods.json"` |  |
| testProfiles.collapseArray.targetFile[0].target | string | `"pods"` |  |
| testProfiles.collapseArray.targetFile[1].file | string | `"/etc/config/services.json"` |  |
| testProfiles.collapseArray.targetFile[1].target | string | `"services"` |  |
| testProfiles.singleFile.*.job-name | string | `"default-job"` |  |
| testProfiles.singleFile.testuser.job-name | string | `"user-job"` |  |
| testRbac.annotations | object | `{}` |  |
| testRbac.clusterRoleCreate | bool | `false` |  |
| testRbac.labels | object | `{}` |  |
| testRbac.namespace | string | `"test-namespace"` |  |
| testRbac.removeNamespaceReferences | bool | `false` |  |
| testRbac.serviceAccountCreate | bool | `true` |  |
| testRbac.serviceAccountName | string | `"test-sa"` |  |
| testRbac.targetNamespace | string | `"test-target"` |  |
| testTplvalues.objectValue.name | string | `"{{ .Release.Name }}"` |  |
| testTplvalues.objectValue.namespace | string | `"{{ .Release.Namespace }}"` |  |
| testTplvalues.staticValue | string | `"static"` |  |
| testTplvalues.templateValue | string | `"{{ .Release.Name }}-suffix"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)
