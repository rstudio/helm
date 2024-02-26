# RStudio Workbench examples

The examples in this directory provide a starting point for deploying RStudio Workbench in
different configurations. Each example has a beginning description and a series of `# TODO` comments.
Before using an example, read through all the comments and ensure you address each `# TODO`.

While each example focuses on one or more particular configurations, RStudio Workbench has some
standard requirements listed in each example. Each example will need the following to run correctly:
- PostgreSQL database specified in the Workbench configuration
- License key or file specified
- homeStorage configured
- sharedStorage configured

## Application Configuration

### [Recommended Application Configuration](./application-configuration/rstudio-workbench-recommended-app-config.yaml)

## Container Image Configuration

### [Using Private Images](./container-images/rstudio-workbench-private-image.yaml)

## Authentication & User Provisioning

### [OIDC SSO Authentication and SSSD User Provisioning](./auth-user-provisioning/rstudio-workbench-oidc-sssd.yaml)

### [SAML SSO Authentication and SSSD User Provisioning](./auth-user-provisioning/rstudio-workbench-saml-sssd.yaml)

## Ingress

### [NGINX Ingress](./ingress/rstudio-workbench-nginx-ingress.yaml)

### [Traefik Ingress](./ingress/rstudio-workbench-traefik-ingress.yaml)

### [ALB Ingress](./ingress/rstudio-workbench-alb-ingress.yaml)

### [GCE Ingress](./ingress/rstudio-workbench-gce-ingress.yaml)

### [Azure Application Gateway Ingress](./ingress/rstudio-workbench-azure-application-gateway-ingress.yaml)

## Storage

### [Additional volumeMounts](./storage/rstudio-workbench-with-additional-mounts.yaml)

### [NFS backed PersistentVolume](./storage/rstudio-workbench-with-pv.yaml)
