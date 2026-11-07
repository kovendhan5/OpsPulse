# Build Guide: OpsPulse (4 weeks)

Work in small steps, commit after each one, and write what you learned in your README. Prompts below are for GitHub Copilot or Claude. Always read and understand generated code before using it, because interviewers will ask "why".

## Before you start
- AWS account with an **AWS Budget alert** (for example, a small monthly limit).
- Installed: Git, Docker, Terraform 1.6+, AWS CLI v2, Python 3.12.
- Create a GitHub repo named `opspulse` and push this folder.
- Find your IP: `curl ifconfig.me` (you will use `x.x.x.x/32`).

## Week 1: Terraform foundation
**Day 1-2: Remote state**
1. `cd infra/bootstrap`, run `terraform init` and `terraform apply` with a unique `state_bucket_name`.
2. Copy `infra/envs/dev/backend.hcl.example` to `backend.hcl` and fill in your bucket.
- *Why:* remote state with locking stops two people corrupting state; versioning lets you recover.

**Day 3-4: Network, registry, node**
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `admin_cidr`.
2. `make tf-init`, `make tf-plan`, then `make tf-apply`.
3. Read each module and explain every resource in your own words.
- *Prompt:* "Explain this Terraform module line by line and tell me what would break if I removed `map_public_ip_on_launch`."

**Day 5: Verify**
- Run the `ssm_shell_command` output, then `sudo kubectl get nodes` on the node. It should show `Ready`.
- Run `terraform apply` again. It should say no changes (idempotent).

**Week 1 checkpoint:** screenshot of `kubectl get nodes` and the Terraform output.

## Week 2: CI pipeline
1. In `gitops/apps/opspulse/kustomization.yaml`, replace `ACCOUNT_ID` with your AWS account id.
2. Add GitHub secret `AWS_ROLE_ARN` (value from Terraform output `github_ci_role_arn`).
3. Push a small change to `app/`. Watch the workflow: test, build, Trivy, push.
4. Deliberately break something (for example, use a very old base image) and watch Trivy block the push. Screenshot it.
- *Prompt:* "Explain how GitHub OIDC replaces stored AWS access keys and why that is more secure."

**Week 2 checkpoint:** a green pipeline run and a red (blocked) run screenshot.

## Week 3: GitOps and observability
1. On the node (via SSM): clone your repo and run `scripts/install-platform.sh`.
2. `kubectl apply -f gitops/argocd/application.yaml`. Open Argo CD (port-forward) and confirm the app is `Synced` and `Healthy`.
3. Port-forward Grafana: `kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80`. Build a dashboard with three panels: request rate, error ratio, p95 latency.
4. Run `scripts/loadgen.sh http://<node-public-ip>` and watch the panels move.
5. Optional: configure an Alertmanager Slack or email receiver.
- *Prompt:* "Give me PromQL for p95 latency from a Prometheus histogram and explain each function."
- Manually edit a deployment on the cluster and watch Argo CD **self-heal** it (this demonstrates drift correction).

**Week 3 checkpoint:** Grafana dashboard screenshot and an Argo CD synced screenshot.

## Week 4: Canary, rollback and polish
1. **Good release:** change `APP_VERSION` to `1.1.0` and push. Watch the canary go 25%, 50%, 100% with `kubectl argo rollouts get rollout opspulse -n opspulse --watch` (install the kubectl plugin if you want the live view).
2. **Bad release:** set `FAIL_RATE` to `"0.5"`, push, keep `loadgen.sh` running. The analysis should fail and the rollout should abort. Record this.
3. Record a 2-minute screen video: commit, pipeline, canary, failure, automatic rollback.
4. Fill the **Results** section in the README with real numbers.
5. Run `make tf-destroy` and confirm no resources remain in the AWS console.

## Troubleshooting checklist
- Pods in `ImagePullBackOff`: check the `ecr-pull` secret exists in the `opspulse` namespace and the image tag exists in ECR.
- Argo CD says `OutOfSync` for the ServiceMonitor: install the monitoring stack first (CRDs must exist).
- Canary always passes: there is no traffic, so start `loadgen.sh`.
- Node out of memory: use `t3.medium` or larger.

## Resume bullets (replace the blanks with your real numbers)
- Built a GitOps delivery platform on AWS using Terraform, GitHub Actions, Argo CD and Argo Rollouts, cutting commit-to-production time to ___ minutes with automated canary rollback in under ___ minutes.
- Defined SLOs (99.5% availability, p95 under 300 ms) with Prometheus alerts and Grafana dashboards; enforced a Trivy security gate and keyless GitHub-to-AWS authentication via OIDC.
