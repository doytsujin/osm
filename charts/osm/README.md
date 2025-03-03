# Open Service Mesh Helm Chart

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: latest-main](https://img.shields.io/badge/AppVersion-latest--main-informational?style=flat-square)

A Helm chart to install the [OSM](https://github.com/openservicemesh/osm) control plane on Kubernetes.

## Prerequisites

- Kubernetes >= 1.19.0-0

## Get Repo Info

```console
helm repo add osm https://openservicemesh.github.io/osm
helm repo update
```

## Install Chart

```console
helm install [RELEASE_NAME] osm/osm
```

The command deploys `osm-controller` on the Kubernetes cluster in the default configuration.

_See [configuration](#configuration) below._

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Uninstall Chart

```console
helm uninstall [RELEASE_NAME]
```

This removes all the Kubernetes components associated with the chart and deletes the release.

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

## Upgrading Chart

```console
helm upgrade [RELEASE_NAME] [CHART] --install
```

_See [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) for command documentation._

## Configuration

See [Customizing the Chart Before Installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with detailed comments, visit the chart's [values.yaml](./values.yaml), or run these configuration commands:

```console
helm show values osm/osm
```

The following table lists the configurable parameters of the osm chart and their default values.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| contour.contour | object | `{"image":{"registry":"docker.io","repository":"projectcontour/contour","tag":"v1.18.0"}}` | Contour controller configuration |
| contour.enabled | bool | `false` | Enables deployment of Contour control plane and gateway |
| contour.envoy | object | `{"image":{"registry":"docker.io","repository":"envoyproxy/envoy-alpine","tag":"v1.19.1"}}` | Contour envoy edge proxy configuration |
| osm.caBundleSecretName | string | `"osm-ca-bundle"` | The Kubernetes secret name to store CA bundle for the root CA used in OSM |
| osm.certificateProvider.certKeyBitSize | int | `2048` | Certificate key bit size for data plane certificates issued to workloads to communicate over mTLS |
| osm.certificateProvider.kind | string | `"tresor"` | The Certificate manager type: `tresor`, `vault` or `cert-manager` |
| osm.certificateProvider.serviceCertValidityDuration | string | `"24h"` | Service certificate validity duration for certificate issued to workloads to communicate over mTLS |
| osm.certmanager.issuerGroup | string | `"cert-manager.io"` | cert-manager issuer group |
| osm.certmanager.issuerKind | string | `"Issuer"` | cert-manager issuer kind |
| osm.certmanager.issuerName | string | `"osm-ca"` | cert-manager issuer namecert-manager issuer name |
| osm.configResyncInterval | string | `"0s"` | Sets the resync interval for regular proxy broadcast updates, set to 0s to not enforce any resync |
| osm.controlPlaneTolerations | list | `[]` | Node tolerations applied to control plane pods. The specified tolerations allow pods to schedule onto nodes with matching taints. |
| osm.controllerLogLevel | string | `"info"` | Controller log verbosity |
| osm.curlImage | string | `"curlimages/curl"` | Curl image for control plane init container |
| osm.deployGrafana | bool | `false` | Deploy Grafana with OSM installation |
| osm.deployJaeger | bool | `false` | Deploy Jaeger during OSM installation |
| osm.deployPrometheus | bool | `false` | Deploy Prometheus with OSM installation |
| osm.enableDebugServer | bool | `false` | Enable the debug HTTP server on OSM controller |
| osm.enableEgress | bool | `false` | Enable egress in the mesh |
| osm.enableFluentbit | bool | `false` | Enable Fluent Bit sidecar deployment on OSM controller's pod |
| osm.enablePermissiveTrafficPolicy | bool | `false` | Enable permissive traffic policy mode |
| osm.enablePrivilegedInitContainer | bool | `false` | Run init container in privileged mode |
| osm.enableReconciler | bool | `false` | Enable reconciler for OSM's CRDs and mutating webhook |
| osm.enforceSingleMesh | bool | `true` | Enforce only deploying one mesh in the cluster |
| osm.envoyLogLevel | string | `"error"` | Log level for the Envoy proxy sidecar. Non developers should generally never set this value. In production environments the LogLevel should be set to `error` |
| osm.featureFlags.enableAsyncProxyServiceMapping | bool | `false` | Enable async proxy-service mapping |
| osm.featureFlags.enableEgressPolicy | bool | `true` | Enable OSM's Egress policy API. When enabled, fine grained control over Egress (external) traffic is enforced |
| osm.featureFlags.enableEnvoyActiveHealthChecks | bool | `false` | Enable Envoy active health checks |
| osm.featureFlags.enableIngressBackendPolicy | bool | `true` | Enables OSM's IngressBackend policy API. When enabled, OSM will use the IngressBackend API allow ingress traffic to mesh backends |
| osm.featureFlags.enableMulticlusterMode | bool | `false` | Enable Multicluster mode. When enabled, multicluster mode will be enabled in OSM |
| osm.featureFlags.enableRetryPolicy | bool | `false` | Enable Retry Policy for automatic request retries |
| osm.featureFlags.enableSnapshotCacheMode | bool | `false` | Enables SnapshotCache feature for Envoy xDS server. |
| osm.featureFlags.enableWASMStats | bool | `true` | Enable extra Envoy statistics generated by a custom WASM extension |
| osm.fluentBit.enableProxySupport | bool | `false` | Enable proxy support toggle for Fluent Bit |
| osm.fluentBit.httpProxy | string | `""` | Optional HTTP proxy endpoint for Fluent Bit |
| osm.fluentBit.httpsProxy | string | `""` | Optional HTTPS proxy endpoint for Fluent Bit |
| osm.fluentBit.name | string | `"fluentbit-logger"` | Fluent Bit sidecar container name |
| osm.fluentBit.outputPlugin | string | `"stdout"` | Fluent Bit output plugin |
| osm.fluentBit.primaryKey | string | `""` | Primary Key for Fluent Bit output plugin to Log Analytics |
| osm.fluentBit.pullPolicy | string | `"IfNotPresent"` | PullPolicy for Fluent Bit sidecar container |
| osm.fluentBit.registry | string | `"fluent"` | Registry for Fluent Bit sidecar container |
| osm.fluentBit.tag | string | `"1.6.4"` | Fluent Bit sidecar image tag |
| osm.fluentBit.workspaceId | string | `""` | WorkspaceId for Fluent Bit output plugin to Log Analytics |
| osm.grafana.enableRemoteRendering | bool | `false` | Enable Remote Rendering in Grafana |
| osm.grafana.image | string | `"grafana/grafana:8.2.2"` | Image used for Grafana |
| osm.grafana.port | int | `3000` | Grafana service's port |
| osm.grafana.rendererImage | string | `"grafana/grafana-image-renderer:3.2.1"` | Image used for Grafana Renderer |
| osm.image.digest | object | `{"osmBootstrap":"","osmCRDs":"","osmController":"","osmInjector":"","osmSidecarInit":""}` | Image digest (defaults to latest compatible tag) |
| osm.image.digest.osmBootstrap | string | `""` | osm-boostrap's image digest |
| osm.image.digest.osmCRDs | string | `""` | osm-crds' image digest |
| osm.image.digest.osmController | string | `""` | osm-controller's image digest |
| osm.image.digest.osmInjector | string | `""` | osm-injector's image digest |
| osm.image.digest.osmSidecarInit | string | `""` | Sidecar init container's image digest |
| osm.image.pullPolicy | string | `"IfNotPresent"` | Container image pull policy for control plane containers |
| osm.image.registry | string | `"openservicemesh"` | Container image registry for control plane images |
| osm.image.tag | string | `"latest-main"` | Container image tag for control plane images |
| osm.imagePullSecrets | list | `[]` | `osm-controller` image pull secret |
| osm.inboundPortExclusionList | list | `[]` | Specifies a global list of ports to exclude from inbound traffic interception by the sidecar proxy. If specified, must be a list of positive integers. |
| osm.injector.autoScale | object | `{"cpu":{"targetAverageUtilization":80},"enable":false,"maxReplicas":5,"memory":{"targetAverageUtilization":80},"minReplicas":1}` | Auto scale configuration |
| osm.injector.autoScale.cpu.targetAverageUtilization | int | `80` | Average target CPU utilization (%) |
| osm.injector.autoScale.enable | bool | `false` | Enable Autoscale |
| osm.injector.autoScale.maxReplicas | int | `5` | Maximum replicas for autoscale |
| osm.injector.autoScale.memory.targetAverageUtilization | int | `80` | Average target memory utilization (%) |
| osm.injector.autoScale.minReplicas | int | `1` | Minimum replicas for autoscale |
| osm.injector.enablePodDisruptionBudget | bool | `false` | Enable Pod Disruption Budget |
| osm.injector.podLabels | object | `{}` | Sidecar injector's pod labels |
| osm.injector.replicaCount | int | `1` | Sidecar injector's replica count (ignored when autoscale.enable is true) |
| osm.injector.resource | object | `{"limits":{"cpu":"0.5","memory":"64M"},"requests":{"cpu":"0.3","memory":"64M"}}` | Sidecar injector's container resource parameters |
| osm.injector.webhookTimeoutSeconds | int | `20` | Mutating webhook timeout |
| osm.maxDataPlaneConnections | int | `0` | Sets the max data plane connections allowed for an instance of osm-controller, set to 0 to not enforce limits |
| osm.meshName | string | `"osm"` | Identifier for the instance of a service mesh within a cluster |
| osm.multicluster | object | `{"gatewayLogLevel":"error"}` | OSM multicluster feature configuration |
| osm.multicluster.gatewayLogLevel | string | `"error"` | Log level for the multicluster gateway |
| osm.osmBootstrap.podLabels | object | `{}` | OSM bootstrap's pod labels |
| osm.osmBootstrap.replicaCount | int | `1` | OSM bootstrap's replica count |
| osm.osmBootstrap.resource | object | `{"limits":{"cpu":"0.5","memory":"128M"},"requests":{"cpu":"0.3","memory":"128M"}}` | OSM bootstrap's container resource parameters |
| osm.osmController.autoScale | object | `{"cpu":{"targetAverageUtilization":80},"enable":false,"maxReplicas":5,"memory":{"targetAverageUtilization":80},"minReplicas":1}` | Auto scale configuration |
| osm.osmController.autoScale.cpu.targetAverageUtilization | int | `80` | Average target CPU utilization (%) |
| osm.osmController.autoScale.enable | bool | `false` | Enable Autoscale |
| osm.osmController.autoScale.maxReplicas | int | `5` | Maximum replicas for autoscale |
| osm.osmController.autoScale.memory.targetAverageUtilization | int | `80` | Average target memory utilization (%) |
| osm.osmController.autoScale.minReplicas | int | `1` | Minimum replicas for autoscale |
| osm.osmController.enablePodDisruptionBudget | bool | `false` | Enable Pod Disruption Budget |
| osm.osmController.podLabels | object | `{}` | OSM controller's pod labels |
| osm.osmController.replicaCount | int | `1` | OSM controller's replica count (ignored when autoscale.enable is true) |
| osm.osmController.resource | object | `{"limits":{"cpu":"1.5","memory":"1G"},"requests":{"cpu":"0.5","memory":"128M"}}` | OSM controller's container resource parameters. See https://docs.openservicemesh.io/docs/guides/ha_scale/scale/ for more details. |
| osm.osmNamespace | string | `""` | Namespace to deploy OSM in. If not specified, the Helm release namespace is used. |
| osm.outboundIPRangeExclusionList | list | `[]` | Specifies a global list of IP ranges to exclude from outbound traffic interception by the sidecar proxy. If specified, must be a list of IP ranges of the form a.b.c.d/x. |
| osm.outboundIPRangeInclusionList | list | `[]` | Specifies a global list of IP ranges to include for outbound traffic interception by the sidecar proxy. If specified, must be a list of IP ranges of the form a.b.c.d/x. |
| osm.outboundPortExclusionList | list | `[]` | Specifies a global list of ports to exclude from outbound traffic interception by the sidecar proxy. If specified, must be a list of positive integers. |
| osm.prometheus.image | string | `"prom/prometheus:v2.18.1"` | Image used for Prometheus |
| osm.prometheus.port | int | `7070` | Prometheus service's port |
| osm.prometheus.resources | object | `{"limits":{"cpu":"1","memory":"2G"},"requests":{"cpu":"0.5","memory":"512M"}}` | Prometheus's container resource parameters |
| osm.prometheus.retention | object | `{"time":"15d"}` | Prometheus data rentention configuration |
| osm.prometheus.retention.time | string | `"15d"` | Prometheus data retention time |
| osm.sidecarImage | string | `"envoyproxy/envoy-alpine@sha256:6502a637c6c5fba4d03d0672d878d12da4bcc7a0d0fb3f1d506982dde0039abd"` | Envoy sidecar image for Linux workloads (v1.19.1) |
| osm.sidecarWindowsImage | string | `"envoyproxy/envoy-windows@sha256:c904fda95891ebbccb9b1f24c1a9482c8d01cbca215dd081fc8c8db36db85f85"` | Envoy sidecar image for Windows workloads (v1.19.1) |
| osm.tracing.address | string | `""` | Address of the tracing collector service (must contain the namespace). When left empty, this is computed in helper template to "jaeger.<osm-namespace>.svc.cluster.local". Please override for BYO-tracing as documented in tracing.md |
| osm.tracing.enable | bool | `false` | Toggles Envoy's tracing functionality on/off for all sidecar proxies in the mesh |
| osm.tracing.endpoint | string | `"/api/v2/spans"` | Tracing collector's API path where the spans will be sent to |
| osm.tracing.image | string | `"jaegertracing/all-in-one"` | Image used for tracing |
| osm.tracing.port | int | `9411` | Port of the tracing collector service |
| osm.validatorWebhook.webhookConfigurationName | string | `""` | Name of the ValidatingWebhookConfiguration |
| osm.vault.host | string | `""` | Hashicorp Vault host/service - where Vault is installed |
| osm.vault.protocol | string | `"http"` | protocol to use to connect to Vault |
| osm.vault.role | string | `"openservicemesh"` | Vault role to be used by Open Service Mesh |
| osm.vault.token | string | `""` | token that should be used to connect to Vault |
| osm.webhookConfigNamePrefix | string | `"osm-webhook"` | Prefix used in name of the webhook configuration resources |
| smi.validateTrafficTarget | bool | `true` | Enables validation of SMI Traffic Target |

<!-- markdownlint-enable MD013 MD034 -->
<!-- markdownlint-restore -->