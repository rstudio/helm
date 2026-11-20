# Changelog

## 0.1.0

- Initial release: the Posit Telemetry server, which receives Opentelemetry data from the Chronicle agents in Posit
  products, and the Clickhouse database it stores that data in, in one pod, with Clickhouse as a sidecar
  container. Requires Kubernetes 1.29 or later
