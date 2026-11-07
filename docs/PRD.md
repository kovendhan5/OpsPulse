# Product Requirements Document: OpsPulse

**Owner:** Kovendhan P. | **Version:** 1.0 | **Timeline:** 4 weeks | **Status:** Draft

## 1. Overview
OpsPulse is a reference platform that ships a microservice to AWS safely and observably. Every change flows through Git, infrastructure is created by code, and a bad release is detected and rolled back automatically.

## 2. Problem statement
Many teams deploy by hand, cannot see why a release failed, and take a long time to roll back. This causes outages, stress and slow delivery. OpsPulse shows how automation plus measurable reliability targets (SLOs) remove those problems.

## 3. Goals
| ID | Goal |
|---|---|
| G1 | 100% of infrastructure is created with Terraform (no manual console clicks) |
| G2 | A commit to Git reaches the cluster automatically through GitOps (Argo CD) |
| G3 | Reliability is measured with SLOs: 99.5% availability, p95 latency under 300 ms |
| G4 | A bad release is detected and rolled back automatically (canary analysis) |
| G5 | Monthly cloud cost stays low by destroying the environment after demos |

## 4. Non-goals (v1)
- No complex business logic. The app exists only to be deployed and observed.
- No multi-region or multi-account setup.
- No service mesh. Canary uses replica-based weighting.

## 5. Users and personas
- **Developer:** pushes code and expects a safe, automatic release.
- **Platform/SRE engineer:** needs dashboards, alerts and a fast rollback path.
- **Recruiter/interviewer:** must understand the project in under 2 minutes (README + demo video).

## 6. Functional requirements
| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR1 | Infrastructure as code | VPC, IAM, ECR and a k3s node created by `terraform apply`; remote state in S3 with DynamoDB locking |
| FR2 | CI pipeline | On push to `main`: tests run, image is built, Trivy scans it, image is pushed to ECR only if the scan passes |
| FR3 | GitOps CD | CI commits the new image tag; Argo CD syncs it to the cluster with self-heal enabled |
| FR4 | Observability | Prometheus scrapes `/metrics`; Grafana shows request rate, error ratio, p95 latency |
| FR5 | Alerting | Alerts fire for error ratio above 0.5% (5 min) and p95 above 300 ms (5 min) |
| FR6 | Progressive delivery | Argo Rollouts canary (25%, 50%, 100%) with Prometheus analysis; failing analysis aborts the rollout |
| FR7 | Security | Least-privilege IAM, IMDSv2 only, non-root container, GitHub OIDC instead of stored AWS keys, no secrets in Git |

## 7. Non-functional requirements
- **Reproducible:** a fresh environment comes up from documented commands.
- **Idempotent:** running `terraform apply` twice changes nothing the second time.
- **Documented:** README with architecture diagram; each step explained in the build guide.
- **Cost-aware:** AWS Budget alert set; environment destroyed after use.

## 8. Architecture summary
GitHub Actions (test, build, scan, push) -> Amazon ECR -> manifest tag updated in Git -> Argo CD syncs -> Argo Rollouts canary on k3s (EC2) -> Prometheus/Grafana/Alertmanager. See the diagram in README.md.

## 9. Tech stack
Terraform, AWS (VPC, EC2, ECR, IAM, S3, DynamoDB, SSM), k3s, Docker, GitHub Actions, Trivy, Argo CD, Argo Rollouts, Prometheus, Grafana, Python (FastAPI).

## 10. Milestones
| Week | Focus | Output |
|---|---|---|
| 1 | Terraform foundation | Remote state, VPC, ECR, k3s node, IAM |
| 2 | CI pipeline | Tests, Docker build, Trivy gate, push to ECR via OIDC |
| 3 | GitOps + observability | Argo CD, Prometheus, Grafana, SLO alerts |
| 4 | Canary + polish | Auto-rollback demo, README, diagram, demo video, resume bullets |

## 11. Success metrics
- Fresh environment ready in under 15 minutes.
- Commit to live in under 5 minutes.
- Failed canary rolled back in under 2 minutes.
- 0 hard-coded credentials in the repository.

## 12. Risks and mitigations
| Risk | Mitigation |
|---|---|
| Cloud cost overrun | AWS Budget alert; `terraform destroy` after each session |
| Scope creep | Follow the non-goals; finish each week before starting the next |
| Single-node k3s is not highly available | State this honestly in the README as a known trade-off and a "next step" |
| Canary analysis passes when there is no traffic | Always run `scripts/loadgen.sh` during demos |

## 13. Future work
Multi-AZ EKS, Karpenter autoscaling, OPA/Kyverno policies, cost dashboard, and an MLOps extension (model serving with drift alerts).

## 14. Deliverables for recruiters
README with diagram, a 2-minute demo video (bad release rolled back), a Grafana SLO screenshot, and two quantified resume bullets.
