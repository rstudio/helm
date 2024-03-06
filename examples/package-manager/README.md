# RStudio Package Manager examples

The examples in this directory provide a starting point for deploying RStudio Package Manager in
different configurations. Each example has a beginning description and a series of `# TODO` comments.
Before using an example, read through all the comments and ensure you address each `# TODO`.

While each example focuses on one or more particular configurations, RStudio Package Manager has some
standard requirements listed in each example. Each example will need the following to run correctly:
- PostgreSQL database specified in the Package Manager configuration
- License key or file specified
- `sharedStorage` or `S3Storage` configured

## Container Image Configuration

### [Custom Images](./container-images/rstudio-pm-custom-image.yaml)

### [Custom Images in Private Registry](./container-images/rstudio-pm-custom-image-private.yaml)

## Ingress

### [NGINX Ingress](./ingress/rstudio-pm-nginx-ingress.yaml)

### [Traefik Ingress](./ingress/rstudio-pm-traefik-ingress.yaml)

### [ALB Ingress](./ingress/rstudio-pm-alb-ingress.yaml)

### [GCE Ingress](./ingress/rstudio-pm-gce-ingress.yaml)

### [Azure Application Gateway Ingress](./ingress/rstudio-pm-azure-application-gateway-ingress.yaml)

## Storage

### [S3 Storage](./storage/rstudio-pm-with-s3.yaml)

### [Additional volumes](./storage/rstudio-pm-with-additional-mounts.yaml)

### [NFS backed PersistentVolume sharedStorage](./storage/rstudio-pm-with-pv.yaml)
