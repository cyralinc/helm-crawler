# Cyral Crawler Helm Chart

Deploy the Cyral Repo Crawler as a Kubernetes CronJob via Helm

Build a value file and run the following command

```shell
helm upgrade -i <release_name> oci://public.ecr.aws/cyral/helm/crawler --version <version_tag> -f <your_value_file.yaml>
```

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

If you arent using the Vault Secrets Operator and would like to use the annotation based approach, you can set it up in the following way.

This example provides both the database credentials and the control plane credentials

```yaml
controlPlane: "stable.dev.cyral.com"
cronjob:
  repoName: myrepo
  podAnnotations:
      vault.hashicorp.com/agent-inject: "true"
      vault.hashicorp.com/agent-pre-populate-only : "true"
      vault.hashicorp.com/role: myrole
      vault.hashicorp.com/tls-skip-verify: "true"
      vault.hashicorp.com/secret-volume-path-config.yaml: "/etc/cyral"
      # Because we're using a merge function, the go template for vault needs to be escaped
      vault.hashicorp.com/agent-inject-template-config.yaml: |
        {{ "{{" }}- with secret "vault/db/myrepo" }}
        "repo-user": "{{ "{{" }} .Data.data.username }}"
        "repo-password": "{{ "{{" }} .Data.data.password }}"
        {{ "{{" }}- end }}
        {{ "{{" }}- with secret "vault/cp/creds" }}
        "cyral-client-id": "{{ "{{" }} .Data.data.clientId }}"
        "cyral-client-secret": "{{ "{{" }} .Data.data.clientSecret }}"
        {{ "{{" }}- end }}
```

## Install and Run On-Demand

clone/download this repository and generate a values file.

```shell
helm install $name .
kubectl create job --from=cronjob/$name $jobname
```

## Advanced Options (Oracle/Snowflake)

For scanning oracle or snowflake additional configuration needs to be added

For Oracle the service name needs to be provided (typically it should be set to `ORCL`)

```yaml
cronjob:
  env:
    - name: REPO_CRAWLER_REPO_ADVANCED
      value: "{\"oracle\":{\"service-name\":\"ORCL\"}}"
```

For Snowflake we need to specify some additional information: Account, Role and Warehouse

```yaml
cronjob:
  env:
      - name: REPO_CRAWLER_REPO_ADVANCED
        value: "{\"snowflake\":{\"account\":\"$account\",\"role\":\"$role\",\"warehouse\":\"$warehouse\"}}"

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
| `cronjob.env`            | Additonal environment variables (used for advanced configuration)                                        | `{}`        |
| `cronjob.schedule`       | Schedule for when to run the crawler                                                                     | `0 0 * * 6` |
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
| `tag`               | Version/Tag of image to pull                                                                              | `v0.12.5`              |
| `imagePullPolicy`   | Pull policy configuration                                                                                 | `IfNotPresent`         |
| `imagePullSecrets`  | Image pull secret configuration                                                                           | `""`                   |
| `kubeVersion`       | Force target Kubernetes version (using Helm capabilities if not set)                                      | `""`                   |
| `nameOverride`      | String to partially override common.names.fullname template with a string (will prepend the release name) | `""`                   |
| `fullnameOverride`  | String to fully override common.names.fullname template with a string                                     | `""`                   |
| `commonAnnotations` | Common annotations to add to all resources.                                                               | `{}`                   |
| `commonLabels`      | Common labels to add to all resources.                                                                    | `{}`                   |
| `clusterDomain`     | Kubernetes cluster domain                                                                                 | `cluster.local`        |
