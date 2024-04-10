# Cyral Crawler Helm Chart

Deploy the Cyral Repo Crawler as a Kubernetes CronJob via Helm

## Deployment Values Examples

### Credentials provided directly in value file

```yaml
controlPlane: tenant.app.cyral.com
credentials:
    clientId: <api_client_id>
    clientSecret: <api_client_secret>
cronjob:
    repoName: <data repo name>
    repoCredentials:
        username: <data repo username>
        password: <data repo password>

```

### Externally managed secrets

If you manage your secrets manually or with an operator you can use the `existingSecret` option.
This is useful for secrets operators like the AWS or Vault secrets operator.

```yaml
controlPlane: tenant.app.cyral.com
credentials:
    existingSecret: <secret name>
cronjob:
    repoName: <data repo name>
    repoCredentials:
        existingSecret: <secret name>

```

For the control plane credentials we expect a `clientId` and `clientSecret` key

```shell
kubectl create secret generic cpcreds --from-literal=clientId=$CLIENT_ID --from-literal=clientSecret=$CLIENT_SECRET
```

For the repo credentials we expect a `username` and `password` key

```shell
kubectl create secret generic datarepocreds --from-literal=username=$USERNAME --from-literal=password=$PASSWORD
```

### Vault Annotations

Credentials can be provide vai Vault annotations as well. The follow example provides both the database credentials
and the control plane credentials

```yaml
controlPlane: "stable.dev.cyral.com"
cronjob:
  repoName: jrich-pg1
  podAnnotations:
      vault.hashicorp.com/agent-inject: "true"
      vault.hashicorp.com/agent-pre-populate-only : "true"
      vault.hashicorp.com/role: jrich
      vault.hashicorp.com/tls-skip-verify: "true"
      vault.hashicorp.com/secret-volume-path-config.yaml: "/etc/cyral"
      vault.hashicorp.com/agent-inject-template-config.yaml: |
        {{- with secret "jrich/db/jrich-pg1" }}
        "repo-user": "{{ .Data.data.username }}"
        "repo-password": "{{ .Data.data.password }}"
        {{- end }}
        {{- with secret "jrich/cp/creds" }}
        "cyral-client-id": "{{ .Data.data.clientId }}"
        "cyral-client-secret": "{{ .Data.data.clientSecret }}"
        {{- end }}
```


## Install and Run On-Demand



If you arent using the Vault Secrets Operator and would like to use the annotation based approach, you can set it up in the following way.


## Parameters

### Require parameters

Parameters related to connection to the Cyral control plane

| Name                         | Description                                                            | Value |
| ---------------------------- | ---------------------------------------------------------------------- | ----- |
| `controlPlane`               | host name of the control plane. typically tenant.app.cyral.com         | `""`  |
| `credentials.existingSecret` | Utilize a pre-existing secret for control plane credentials            | `""`  |
| `credentials.clientId`       | The Cyral Client ID to be used for connecting to the control plane     | `""`  |
| `credentials.clientSecret`   | The Cyral Client Secret to be used for connecting to the control plane | `""`  |
| `credentials.annotations`    | Annotations for the secret                                             | `{}`  |
| `credentials.labels`         | Labels for the secret                                                  | `{}`  |

### cronjob Cronjob configuration parameters

| Name                     | Description                                                                                              | Value       |
| ------------------------ | -------------------------------------------------------------------------------------------------------- | ----------- |
| `cronjob.repoName`       | Data repo name to be scanned                                                                             | `""`        |
| `cronjob.repoHost`       | host address to use to connect to the database. If not provided it will be pulled from the control plane | `""`        |
| `cronjob.annotations`    |                                                                                                          | `{}`        |
| `cronjob.podAnnotations` | Used to apply annotations to the job pod itself. Useful for Vault                                        | `{}`        |
| `cronjob.labels`         |                                                                                                          | `{}`        |
| `cronjob.schedule`       |                                                                                                          | `0 0 * * 6` |
| `cronjob.restartPolicy`  |                                                                                                          | `Never`     |
| `cronjob.resources`      | Job Resource definition                                                                                  |             |

### cronjob.serviceAccount

| Name                                 | Description | Value  |
| ------------------------------------ | ----------- | ------ |
| `cronjob.serviceAccount.create`      |             | `true` |
| `cronjob.serviceAccount.annotations` |             | `{}`   |
| `cronjob.serviceAccount.labels`      |             | `{}`   |
| `cronjob.serviceAccount.name`        |             | `""`   |

### cronjob.repoCredentials

| Name                                     | Description | Value |
| ---------------------------------------- | ----------- | ----- |
| `cronjob.repoCredentials.annotations`    |             | `{}`  |
| `cronjob.repoCredentials.labels`         |             | `{}`  |
| `cronjob.repoCredentials.existingSecret` |             | `""`  |
| `cronjob.repoCredentials.username`       |             | `""`  |
| `cronjob.repoCredentials.password`       |             | `""`  |

### Optional Configuration

| Name                | Description                                                                                               | Value                  |
| ------------------- | --------------------------------------------------------------------------------------------------------- | ---------------------- |
| `imageRegistry`     | Image registry to pull the crawler image from                                                             | `public.ecr.aws/cyral` |
| `tag`               | Version/Tag of image to pull                                                                              | `v0.11.1`              |
| `imagePullPolicy`   | Pull policy configuration                                                                                 | `IfNotPresent`         |
| `imagePullSecrets`  | Image pull secret configuration                                                                           | `""`                   |
| `kubeVersion`       | Force target Kubernetes version (using Helm capabilities if not set)                                      | `""`                   |
| `nameOverride`      | String to partially override common.names.fullname template with a string (will prepend the release name) | `""`                   |
| `fullnameOverride`  | String to fully override common.names.fullname template with a string                                     | `""`                   |
| `commonAnnotations` | Common annotations to add to all Cyral Sidecar resources.                                                 | `{}`                   |
| `commonLabels`      | Common labels to add to all Cyral Sidecar resources.                                                      | `{}`                   |
| `clusterDomain`     | Kubernetes cluster domain                                                                                 | `cluster.local`        |
