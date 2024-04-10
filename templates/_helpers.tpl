{{/*
Copyright Cyral, Inc.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/*
Create payload for any image pull secret.
One kube secret will be created containing all the auths
and will be shared by all the job pods requiring it.
*/}}
{{- define "cronjobs.imageSecrets" -}}
    {{- $secrets := dict -}}
    {{- $job := .Values.cronjob -}}
    {{- if hasKey $job "imagePullSecrets" -}}
        {{- range $ips := $job.imagePullSecrets -}}
            {{- $userInfo := dict "username" $ips.username "password" $ips.password "auth" (printf "%s:%s" $ips.username $ips.password | b64enc) -}}
            {{- if hasKey $ips "email" -}}
                {{ $_ := set $userInfo  "email" $ips.email -}}
            {{- end -}}
            {{- $_ := set $secrets $ips.registry $userInfo -}}
        {{- end -}}
    {{- end -}}
    {{- if gt (len $secrets) 0 -}}
        {{- $auth := dict "auths" $secrets -}}
        {{/* Emit secret content as base64 */}}
        {{- print ($auth | toJson | b64enc) -}}
    {{- else -}}
        {{/* There are no secrets*/}}
        {{- print "" -}}
    {{- end -}}
{{- end -}}

{{/*
Return true if a secret for Cyral Sidecar credentials should be created
*/}}
{{- define "cyral.createCpCredentialsSecret" -}}
{{- if and (not .Values.credentials.existingSecret) .Values.credentials.clientId .Values.credentials.clientSecret -}}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Get Cyral cp credentials secret. If neither is used, Vault is expected
*/}}
{{- define "cyral.cpCredentials.secretName" -}}
{{- if (include "cyral.createCpCredentialsSecret" .) -}}
    {{ $.Release.Name }}-cyral-credentials
{{- else if not (empty .Values.credentials.existingSecret) -}}
    {{- tpl .Values.credentials.existingSecret $ -}}
{{- else -}}
    {{- print "" -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a secret for the repo credentials should be created
*/}}
{{- define "cyral.createRepoCredentialsSecret" -}}
{{- if and (not .Values.cronjob.repoCredentials.existingSecret) .Values.cronjob.repoCredentials.username .Values.cronjob.repoCredentials.password -}}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Get Cyral repo credentials secret. If neither is used, Vault is expected
*/}}
{{- define "cyral.repoCredentials.secretName" -}}
{{- if (include "cyral.createRepoCredentialsSecret" .) -}}
    {{ $.Release.Name }}-repo-credentials
{{- else if not (empty .Values.cronjob.repoCredentials.existingSecret) -}}
    {{- tpl .Values.cronjob.repoCredentials.existingSecret $ -}}
{{- else -}}
    {{- print "" -}}
{{- end -}}
{{- end -}}

{{/*
 Create the name of the service account to use
 */}}
{{- define "cyral.serviceAccountName" -}}
{{- if .Values.cronjob.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.cronjob.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.cronjob.serviceAccount.name }}
{{- end -}}
{{- end -}}