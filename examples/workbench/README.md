# RStudio Workbench examples

### [RStudio Workbench with Custom NFS Mount Options](./rstudio-workbench-with-pv.yaml)

This example deploys RStudio Workbench with a PersistentVolume.

The PersistentVolume allows setting NFS mountOptions. It creates a storage class that RStudio Workbench then takes
advantage of when it creates its PersistentVolumeClaim.

PVC and PV will be left around after the helm release is removed (for manual cleanup). This protects data from being
deleted

### [RStudio Workbench with a Single Node and `sssd`](./rstudio-workbench-single-node-with-sssd.yaml)

This example deploys RStudio Workbench with a single node. `strategy` and `replicas` are set accordingly, and this setup
should work even if using a `ReadWriteOnce` storage class. NOTE that the SQLite database will reside on the `sharedStorage`
persistent volume claim.

- Set `replicas: 1`
- Set strategy to `Recreate` so that the pod is stopped before starting another
- Create separate `homeStorage` and `sharedStorage` PVCs
- Configure `sssd` to point at an example domain and connect to LDAP with a bind account and password

NOTE: before upgrading to HA, you will need to:
- Switch / migrate to using PostgreSQL as a database
- Migrate the `sharedStorage` and `homeStorage` to a `ReadWriteMany` (`RWX`) storage class like NFS
