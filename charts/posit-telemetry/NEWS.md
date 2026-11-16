# Changelog

## 0.1.0

- Initial release: a chronicle server, which stores Opentelemetry data from the agents in Posit products. Set
  `serverType` to `posit-telemetry` (the default) to also deploy the Clickhouse database it writes to, or to
  `chronicle` for the classic server, which stores data on a local volume and/or in S3 instead
