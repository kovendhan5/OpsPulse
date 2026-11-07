# Interview Story: OpsPulse

## 30-second pitch
"I built OpsPulse, a delivery platform on AWS. Terraform creates the infrastructure, GitHub Actions tests and scans every build, Argo CD deploys from Git, and a canary release checks the error rate in Prometheus. If a release is bad, it rolls back automatically. I built it to show the full journey from commit to a monitored, safe release."

## The story (use STAR)
- **Situation:** Manual deployments are slow and risky, and teams often find out about a bad release from users.
- **Task:** Build a platform where every change is automated, measured and reversible.
- **Action:** I defined everything in Terraform, built a CI pipeline with a Trivy security gate, used GitOps with Argo CD, and added a canary analysis driven by Prometheus metrics.
- **Result:** Commit to live in ___ minutes; a bad release was rolled back in ___ seconds without human action.

## What / How / Why
| Part | What | How | Why |
|---|---|---|---|
| Terraform | Creates VPC, ECR, node, IAM | Modules + remote state | Repeatable, reviewable, idempotent |
| GitHub OIDC | CI logs in to AWS | Role trusted for one repo and branch | No long-lived keys to leak |
| Trivy | Scans images | Fails build on fixable HIGH/CRITICAL | Shift security left |
| Argo CD | Deploys from Git | Watches `gitops/`, self-heal on | Git is the source of truth; fixes drift |
| Argo Rollouts | Canary release | 25%, 50%, 100% with analysis | Limits blast radius |
| Prometheus | Metrics and rules | Scrapes `/metrics` | Evidence for decisions and alerts |

## Questions to practise (answer aloud, 60 seconds each)
1. Why GitOps instead of `kubectl apply` from CI?
2. What does idempotent mean, and how did you check it?
3. What is a canary release, and what is the blast radius?
4. How do you define an SLO, and why 99.5%?
5. Why use k3s instead of EKS here? What would you change for production?
6. What happens if the canary receives no traffic? (Be honest: the analysis could pass wrongly, so I run a load generator and treat "no data" as a known limitation.)
7. How did you avoid storing AWS keys in GitHub?
8. What was the hardest bug, and how did you debug it?

## Honest limitations (say these before they ask)
Single node is not highly available; public subnets without NAT were chosen for cost; the canary weights are replica-based because there is no service mesh. "Next step" is multi-AZ EKS and private subnets.

## Vocabulary to use naturally
idempotent, drift, blast radius, least privilege, rollback, canary, SLO/SLI, error budget, source of truth, reconcile, provisioning.
