.PHONY: test run build tf-bootstrap tf-init tf-plan tf-apply tf-destroy loadgen

test:
	cd app && pip install -q -r requirements-dev.txt && pytest -q

run:
	cd app && uvicorn main:app --reload --port 8000

build:
	docker build -t opspulse-app:local app

tf-bootstrap:
	cd infra/bootstrap && terraform init && terraform apply

tf-init:
	cd infra/envs/dev && terraform init -backend-config=backend.hcl

tf-plan:
	cd infra/envs/dev && terraform plan

tf-apply:
	cd infra/envs/dev && terraform apply

tf-destroy:
	cd infra/envs/dev && terraform destroy

loadgen:
	./scripts/loadgen.sh $(URL)
