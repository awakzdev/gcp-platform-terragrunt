# GCP Platform — Terragrunt / Terraform

> Production-grade Google Cloud Platform infrastructure for a SaaS automotive platform, built and owned end-to-end as sole DevOps architect. All sensitive values (project IDs, account numbers, domains) have been anonymised.

---

## Overview

Full multi-environment GCP platform provisioned with **Terraform** and **Terragrunt**, serving a production SaaS product with real customer traffic. The platform handles everything from networking and compute to security, observability, and GitOps deployment.

Built and maintained solo — no team, no handoff. Every component below was designed, implemented, and operates in production.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        GCP Organisation                      │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │     dev      │  │   staging    │  │      prod        │  │
│  │  GKE cluster │  │  GKE cluster │  │   GKE cluster    │  │
│  │  Cloud SQL   │  │  Cloud SQL   │  │   Cloud SQL HA   │  │
│  │  VPC/Subnets │  │  VPC/Subnets │  │   VPC/Subnets    │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│           │                │                  │              │
│           └────────────────┴──────────────────┘              │
│                            │                                 │
│                   Shared Services VPC                        │
│              (Artifact Registry, Secret Manager,             │
│               Cloud Armor, Cloud CDN, DNS)                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Stack

| Layer | Technology |
|---|---|
| IaC | Terraform >= 1.6, Terragrunt |
| Compute | GKE Autopilot + Standard node pools |
| Database | Cloud SQL (PostgreSQL), private IP, HA in prod |
| Networking | Custom VPC, private subnets, Cloud NAT, VPC peering |
| Security | Cloud Armor WAF, Secret Manager, Workload Identity, CIS-hardened nodes |
| CDN / DNS | Cloud CDN, Cloud Load Balancing, Cloud DNS |
| Registry | Artifact Registry (Docker images) |
| GitOps | ArgoCD + Helm, environment-gated promotion |
| CI/CD | GitLab CI — plan → apply pipeline per environment |
| Observability | Grafana, Prometheus, Loki — deployed via Helm |
| Service Mesh | Config Connector for GCP resource management from Kubernetes |

---

## Repository Structure

```
.
├── infrastructure-definition/     # Reusable Terraform modules
│   ├── gke/                       # GKE cluster (node pools, RBAC, Workload Identity)
│   ├── cloud-sql/                 # Cloud SQL with private IP, backups, HA
│   ├── vpc/                       # VPC, subnets, NAT, firewall rules
│   ├── dns/                       # Cloud DNS zones and records
│   ├── cdn/                       # Cloud CDN + Load Balancer
│   ├── artifact-registry/         # Docker image registry
│   └── secret-manager/            # Secret Manager with IAM bindings
│
├── infrastructure-assignment/     # Terragrunt live configuration
│   ├── terragrunt.hcl             # Root config — remote state, provider, common vars
│   ├── dev/
│   │   ├── gke/terragrunt.hcl
│   │   ├── cloud-sql/terragrunt.hcl
│   │   └── vpc/terragrunt.hcl
│   ├── staging/
│   └── prod/
│
└── cluster-infra/                 # Kubernetes manifests + Helm values
    ├── argocd/
    ├── monitoring/
    └── ingress/
```

---

## Key Design Decisions

**Terragrunt DRY pattern** — a single root `terragrunt.hcl` defines the GCS remote state backend, provider version, and shared inputs. Each environment folder inherits these and overrides only what differs (machine type, replica count, etc.). Zero code duplication across dev/staging/prod.

**Workload Identity over service account keys** — GKE workloads authenticate to GCP APIs (Cloud SQL, Secret Manager, GCS) via Workload Identity Federation. No static keys, no secrets in Kubernetes.

**Private GKE cluster** — nodes have no public IPs. All traffic routes through Cloud NAT for egress and internal Load Balancers for internal service communication.

**Cloud Armor WAF** — OWASP ruleset applied at the load balancer layer before traffic reaches GKE ingress. Rate limiting and geo-restriction configured per environment.

**GitLab CI gated deployments** — `terraform plan` runs on every MR. `terraform apply` is gated behind manual approval for staging and prod. State is stored in GCS with object versioning enabled.

---

## Environments

| Environment | GKE Type | Cloud SQL | Replicas |
|---|---|---|---|
| dev | Autopilot | Single, db-f1-micro | 1 |
| staging | Standard, e2-standard-2 | Single, db-g1-small | 2 |
| prod | Standard, n2-standard-4 | HA, db-custom-4-16384 | 3+ |

---

## Usage

```bash
# Deploy dev environment
cd infrastructure-assignment/dev/gke
terragrunt init
terragrunt plan
terragrunt apply

# Deploy all layers in order (VPC → SQL → GKE)
cd infrastructure-assignment/dev
terragrunt run-all apply --terragrunt-non-interactive
```

---

## Notes

This repository contains sanitised infrastructure code. Project IDs, domain names, and account-specific values have been replaced with placeholders. The patterns, module structure, and configurations reflect the actual production system.

Live platform: **example.com**
