# RStudio Workbench examples

### [RStudio Workbench with Custom NFS Mount Options](./rstudio-workbench-with-pv.yaml)

This example deploys RStudio Workbench with a PersistentVolume.

The PersistentVolume allows setting NFS mountOptions. It creates a storage class that RStudio Workbench then takes
advantage of when it creates its PersistentVolumeClaim.

PVC and PV will be left around after the helm release is removed (for manual cleanup). This protects data from being
deleted
