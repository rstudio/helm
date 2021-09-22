# 0.2.5

- Added a new parameter `clusterRoleCreate` to `values.yaml` to allow for disabling the creation of the         
  `ClusterRole` that allows for access to the nodes API. This API is used to ensure that all of the IP addresses
  for nodes are available when reporting the addresses of the node that is running a particular job so that
  clients can connect to it. This is generally not a needed permission for the Launcher as the internal IP is
  usually sufficient, so it is disabled by default.

# 0.1.2

- Specify namespace in ClusterRoleBinding always (it is required)
    - This is unfortunate, because it makes our output YAML examples less portable

# 0.1.1

- Add `services.delete` permissions, which are required for proper launcher functioning

# 0.1.0

- Initial release
