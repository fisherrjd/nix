<!-- Build a pog script: `nix build .#pog_test` -->

# 🥇 Pog — Scripting Like a *NERD*

A collection of handy pog scripts for Docker, Kubernetes, AWS, and more.

---

## 🛠 Jade's Pogs

### `pog_test`

> Testing out pogging.

---

## 🐳 Cobi's Docker Pogs

| Script   | Description |
|----------|-------------|
| `da`     | Lists all Docker containers on the host. Supports JSON output and a "wide" mode to show extra columns like creation time and size. |
| `drm`    | Quickly remove (delete) one or more Docker containers. Uses fuzzy finder for interactive selection and supports force removal. |
| `drmi`   | Quickly remove (delete) one or more Docker images. Uses fuzzy finder for interactive selection and supports force removal. |
| `_dex`   | Interactive tool to exec into a running Docker container. Lets you select a container and opens a shell inside it. |
| `dshell` | Launches a new shell in a Docker container from a specified image. Supports options for port mapping, mounting nix or the current directory, running as a specific user, and custom commands. |
| `dlog`   | Tails logs from one or more Docker containers, with interactive container selection and a configurable "since" time. |
| `dlint`  | Runs hadolint on a Dockerfile with a prescriptive set of ignores, for Dockerfile linting. |

---

## ☸️ Cobi's Kubernetes Pogs

| Script      | Description |
|-------------|-------------|
| `ka`        | Shorthand to list all pods in a namespace or across all namespaces, with optional JSON output. |
| `kex`       | Interactive tool to exec into a selected Kubernetes pod using a shell. |
| `krm`       | Interactive tool to delete one or more pods, with optional force deletion. |
| `klist`     | Lists all container images currently in use across the cluster, with counts. |
| `kshell`    | Launches an ephemeral shell in a new pod, specifying image, namespace, and service account. |
| `kroll`     | Rolls (restarts) a deployment’s pods, with interactive deployment selection. |
| `kdesc`     | Interactive describe for any Kubernetes object in a namespace. |
| `kedit`     | Interactive edit for any Kubernetes object in a namespace. |
| `kdrain`    | Drains one or more nodes, with optional force, for maintenance or upgrades. |
| `klog`      | Tails logs from one or more pods/containers, with filtering, time range, and namespace options (uses stern). |
| `kdiff`     | Shows a diff between a local manifest file and the live cluster, with client/server-side diff options. |
| `ksecedit`  | Fetches a secret, decodes it for inline editing, and re-applies it (handles base64 encoding/decoding). |
| `refresh_secret` | Annotates an external secret to trigger a refresh, interactively selecting the secret. |
| `kimg`      | Lists pod names and their image hashes, optionally across all namespaces. |

---

## ☁️ Cobi's AWS Pogs

| Script           | Description |
|------------------|-------------|
| `aws_id`         | Quickly retrieves your AWS account ID for a given region. |
| `ecr_login`      | Logs in to AWS Elastic Container Registry (ECR) for private registries, using Docker. |
| `ecr_login_public` | Logs in to AWS public ECR, using Docker. |
| `ec2_spot_interrupt` | Looks up EC2 spot instance interruption rates, with optional minimum CPU/RAM filters. Fetches and displays spot market data in a table. |
| `eks_config`     | Fetches and configures a kubeconfig for a selected EKS (Elastic Kubernetes Service) cluster, with interactive cluster selection. |
| `wasabi`         | Wrapper for the AWS CLI to interact with Wasabi S3-compatible storage, using a specified profile and endpoint. |
| `cloudflare_r2`  | Wrapper for the AWS CLI to interact with Cloudflare R2 S3-compatible storage, using a specified profile and endpoint. |
| `awslocal`       | Wrapper for the AWS CLI to interact with LocalStack (local AWS cloud emulator), setting test credentials and endpoint. |
