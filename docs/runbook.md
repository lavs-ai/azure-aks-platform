# Incident Runbook — AKS Platform Demo

Check in this order: pods, then events, then logs, then the platform.
Do not change two things at once.

## 1. Pod crash (CrashLoopBackOff)

**Symptoms:** pod restarts repeatedly; `kubectl get pods` shows
`CrashLoopBackOff`; readiness probe never passes.

**Checks:**

```bash
kubectl -n <namespace> get pods
kubectl -n <namespace> describe pod <pod-name>   # events at the bottom
kubectl -n <namespace> logs <pod-name> --previous
kubectl -n <namespace> get events --sort-by=.lastTimestamp | tail -20
```

**Common causes (in order):** bad image tag, missing ConfigMap/Secret,
resource limits too low (OOMKilled — look for exit code 137 in
`describe`), failed liveness probe (app not listening on port 80).

**Recovery:** fix the cause, not the symptom. If it is a bad image,
roll back: `helm rollback <release> -n <namespace>`. If it is a
resource limit, raise it in the environment values file and redeploy.
Do not delete the pod and hope — the Deployment will recreate the
same broken pod.

## 2. Rollout failure (new version never becomes ready)

**Symptoms:** `helm upgrade` succeeds but `kubectl rollout status`
times out; old pods still serving; new ReplicaSet stuck at 0 ready.

**Checks:**

```bash
kubectl -n <namespace> rollout status deployment/<name>
kubectl -n <namespace> rollout history deployment/<name>
kubectl -n <namespace> describe deployment <name>
kubectl -n <namespace> get pods -l app.kubernetes.io/instance=<release>
```

**Common causes:** new image does not exist in ACR (check the tag),
readiness probe failing (app changed its health endpoint), resource
quota in the namespace.

**Recovery:** `helm rollback <release> -n <namespace>` returns to the
last working release. Then fix the image tag or probe in the chart
and redeploy to SIT first — never debug a rollout directly in UAT.

## 3. Key Vault access denied

**Symptoms:** app logs show `Forbidden` / `access denied` reading a
secret; pods start but cannot load configuration; Azure Monitor shows
Key Vault 403s.

**Checks:**

```bash
# Which identity is the workload using?
kubectl -n <namespace> describe pod <pod-name> | grep -i identity
# In Azure:
az keyvault show --name kv-aks-platform-demo --query properties.accessPolicies
az role assignment list --scope <key-vault-id> --query "[].{role:roleDefinitionName, principal:principalId}"
```

**Common causes:** the cluster identity does not have the
`Key Vault Secrets User` role (see `terraform/main.tf`,
`azurerm_role_assignment.aks_key_vault_reader`), the secret name is
wrong, or the workload is using a different identity than the one
that was granted access.

**Recovery:** grant the *specific* identity the *specific* role it
needs — `Key Vault Secrets User` on the vault, nothing broader.
Re-check with `az keyvault secret show`. Never work around it by
putting the secret in a values file or an environment variable in Git.
