# Azure AKS Platform — Advanced Platform Engineering Project

A production-shaped Azure platform, built from scratch with Terraform, AKS,
Helm and Azure DevOps. It is a portfolio project: the infrastructure is real
and deployable in principle, the demo app is deliberately small so the
platform — not the app — is what is being shown.

Author: Lavanya Bangari, Melbourne, Australia.

## What it is

A hub VNet with private AKS, an Azure Container Registry, Key Vault, and a
Log Analytics workspace, all deployed by Terraform from Azure DevOps, with
the demo app delivered by Helm to SIT, then UAT, then prod — each environment
a separate Helm release with its own values file.

## Architecture

```text
                    Azure DevOps (azure-pipelines.yml)
                               |
                Terraform fmt / validate / plan
                               |
        +----------------------+----------------------+
        |                      |                      |
   modules/network       modules/aks            acr / keyvault /
   VNet + subnets        AKS cluster            log analytics
   (aks, app subnets)    system node pool
                         autoscaling 1-3
                               |
                    Helm releases (helm/app)
                  SIT -> UAT -> prod (manual)
                               |
                    Azure Monitor alerts
              (node CPU, pod restarts, failed pods)
```

Flow:

```text
Developer push to main
  -> Azure DevOps: terraform fmt/validate/plan, helm lint/template
  -> Deploy to SIT (automatic)
  -> Deploy to UAT (manual approval in Azure DevOps)
  -> Prod is a separate, manually-triggered release (same chart, prod values)
```

Services used: Azure Resource Group, Virtual Network, AKS, Azure Container
Registry, Key Vault, Log Analytics, Azure Monitor, Azure DevOps, Entra ID
(managed identities, role assignments — no service-principal secrets).

## Repository layout

```text
terraform/
  main.tf            # composition: modules + ACR + Key Vault + Log Analytics
  variables.tf       # all inputs, with defaults for a demo deployment
  outputs.tf         # cluster name, ACR login server, Key Vault URI
  modules/network/   # VNet + subnets (reusable module)
  modules/aks/       # AKS cluster (reusable module)
helm/app/            # demo web app chart, written from scratch
  Chart.yaml
  values.yaml        # shared defaults (prod-shaped)
  values-sit.yaml    # SIT overrides: 1 replica, small resources
  values-uat.yaml    # UAT overrides: 2 replicas, larger resources
  templates/         # deployment, service, configmap, helpers
azure-pipelines.yml  # CI/CD: validate, plan, SIT deploy, UAT approval
docs/
  INTERVIEW.md       # likely interview questions, answers, trade-offs
  runbook.md         # incident runbook: pod crash, rollout, Key Vault
```

## How to deploy

Prerequisites: Azure subscription, `az`, `terraform` (>= 1.5), `helm`,
`kubectl`, and an Azure DevOps project with a service connection to Azure.
No secrets are stored in this repo — ever. The pipeline uses the Azure
DevOps service connection, not a checked-in credential.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit: location, names
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Get cluster credentials (read-only for your own shell; do not commit output):

```bash
az aks get-credentials --resource-group rg-aks-platform-demo \
  --name aks-platform-demo --overwrite-existing
kubectl get nodes
```

Deploy the app to SIT:

```bash
helm upgrade --install demo-app-sit helm/app \
  --namespace sit --create-namespace \
  -f helm/app/values-sit.yaml
kubectl -n sit get pods,svc
```

UAT is the same command with `demo-app-uat`, namespace `uat`, and
`-f helm/app/values-uat.yaml`.

Destroy when finished (this is a demo — do not leave it running):

```bash
terraform destroy
```

## How to run locally (no Azure needed)

Validate the chart and the pipeline without a cluster:

```bash
helm lint helm/app
helm template demo-app helm/app -f helm/app/values-sit.yaml
helm template demo-app helm/app -f helm/app/values-uat.yaml
terraform fmt -check -recursive terraform/
terraform validate   # after terraform init, in terraform/
python3 -c "import yaml,glob; [yaml.safe_load(open(f)) for f in glob.glob('**/*.y*ml', recursive=True)]; print('YAML OK')"
```

To run the app itself locally, any static web server works — the chart
runs `nginx:1.27-alpine` serving a ConfigMap-generated `index.html`.
There is no application code to build: the point of this project is the
platform, and keeping the app trivial keeps that honest.

## What it proves (for a Senior Platform / DevOps Engineer interview)

- **Terraform at scale:** composition over copy-paste — reusable
  `network` and `aks` modules, typed variables, outputs, tags on
  everything, least-privilege role assignments.
- **Kubernetes, properly:** private AKS, Azure CNI, autoscaling node
  pool, resource requests/limits, liveness/readiness probes, rolling
  updates with `maxSurge`/`maxUnavailable`.
- **Helm, written from scratch:** one chart, three environments via
  values files — SIT and UAT differ in replicas, resources and image
  tag, with no duplicated templates.
- **CI/CD with gates:** Terraform plan on every PR, automatic deploy to
  SIT on `main`, manual approval before UAT — the same shape as a
  real release train.
- **Security, by default:** no secrets in Git, managed identities,
  Key Vault for secrets, ACR pull via the AKS kubelet identity,
  network segmentation (separate AKS and app subnets).
- **Operability:** Log Analytics + Azure Monitor alerts, and a written
  runbook for the three failures most likely to be asked about in an
  interview (`docs/runbook.md`).

## Costs

This creates real Azure resources (AKS, ACR, Key Vault, Log Analytics).
It is a demo — deploy it, show it working, then `terraform destroy`.
Do not leave it running unattended.
