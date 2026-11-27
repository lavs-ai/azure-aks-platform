# Interview Notes — Azure AKS Platform

How to talk about this project in a Senior Platform / DevOps Engineer
interview. Keep answers short, name the file or decision, and stop.

## 5 likely questions

### 1. "Walk me through this project."
"Terraform in `terraform/` builds a VNet, a private AKS cluster, ACR,
Key Vault and Log Analytics. The network and the cluster are reusable
modules, so the root module is composition, not copy-paste. Azure DevOps
validates and plans on every PR, deploys to SIT automatically on `main`,
and deploys to UAT only after a manual approval. The app is a small
Helm chart I wrote from scratch — one chart, three environments via
values files."

### 2. "How do you handle secrets?"
"No secrets in Git, ever — `.gitignore` blocks `terraform.tfvars` and
state files, and the pipeline uses an Azure DevOps service connection,
not a checked-in credential. At runtime, secrets live in Key Vault.
The AKS cluster identity has only the `Key Vault Secrets User` role —
it can read secrets, not manage them. ACR pull is the same idea: the
kubelet identity has `AcrPull` and nothing else, and ACR admin is off."

### 3. "What happens when a deploy goes wrong?"
"Helm does a rolling update with `maxSurge: 1` and `maxUnavailable: 0`,
so the old pods stay up until the new ones pass their readiness probe.
If the rollout stalls, `kubectl rollout status` shows it, and the
runbook in `docs/runbook.md` covers the three cases I would hit first:
pod crash, rollout failure, Key Vault access denied. Rollback is
`helm rollback <release>`."

### 4. "Why private AKS, and what does it cost you operationally?"
"The API server is not exposed to the public internet — that is the
right default for anything that will hold real data. The trade-off is
that you need a jump host or a private build agent to reach it, and
`az aks get-credentials` has to run from inside the network. I chose
that trade-off deliberately and documented it, rather than leaving a
public cluster and calling it a demo."

### 5. "SIT vs UAT — why both, and how do they differ?"
"SIT is for fast feedback: 1 replica, small resources, automatic
deploy on every merge to `main`. UAT is prod-shaped: 2 replicas,
larger resource limits, and a manual approval gate in Azure DevOps.
A pass in UAT means something because the shape matches prod. The
difference is only in `values-sit.yaml` vs `values-uat.yaml` — the
templates are identical, so there is no environment drift in the
chart itself."

## 3 trade-offs made, and why

1. **Private AKS over public AKS.** Safer by default; harder to reach
   from a laptop. Chosen because a platform engineer's default should
   be closed, and the access problem is solvable with a jump host or
   private agent.
2. **System node pool only, no separate user pool.** Keeps the demo
   small and cheap, and autoscaling still works. In production I would
   add a dedicated user pool and keep the system pool for system pods
   only — that is stated in the module comment, not hidden.
3. **Key Vault access policies instead of RBAC-only.** The module uses
   the access-policy model for the deploying identity and a role
   assignment for the cluster identity. That is the simpler model to
   read in a portfolio; in a real team I would move fully to Azure RBAC
   for Key Vault and drop access policies, for a single audit path.

## What not to claim

Do not present this as a production system, a client deployment, or a
measured result. It is a portfolio project: deployable in principle,
not a system that has carried real traffic. Say that plainly if asked.
