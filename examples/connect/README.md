# RStudio Connect examples

The examples in this directory provide a starting point for deploying RStudio Connect in
different configurations. Each example has a beginning description and a series of `# TODO` comments.
Before using an example, read through all the comments and ensure you address each `# TODO`.

While each example focuses on one or more particular configurations, RStudio Connect has some
standard requirements listed in each example. Each example will need the following to run correctly:
- PostgreSQL database specified in the Connect configuration
- License key or file specified
- `sharedStorage` configured


## Application Configuration

### [Recommended Application Configuration](./application-configuration/rstudio-connect-recommended-app-config.yaml)

## Container Image Configuration

### [Off-Host with Custom Images](./container-images/rstudio-connect-custom-image.yaml)

### [Off-Host with Custom Images in Private Registry](./container-images/rstudio-connect-custom-image-private.yaml)

## Authentication & User Provisioning

### [OIDC SSO Authentication](./auth/rstudio-connect-oidc.yaml)

### [SAML SSO Authentication](./auth/rstudio-connect-saml.yaml)

## Ingress

### [NGINX Ingress](./ingress/rstudio-connect-nginx-ingress.yaml)

### [Traefik Ingress](./ingress/rstudio-connect-traefik-ingress.yaml)

### [ALB Ingress](./ingress/rstudio-connect-alb-ingress.yaml)

### [GCE Ingress](./ingress/rstudio-connect-gce-ingress.yaml)

### [Azure Application Gateway Ingress](./ingress/rstudio-connect-azure-application-gateway-ingress.yaml)

## Storage

### [Additional volumes](./storage/rstudio-connect-with-additional-mounts.yaml)

### [NFS backed PersistentVolume](./storage/rstudio-connect-with-pv.yaml)

## Migration

### [Beta Migration](./beta-migration/README.md)
