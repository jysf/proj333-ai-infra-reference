aws_profile := env_var_or_default("AWS_PROFILE", "GBFAdministratorAccess-716522590236")

# Show available recipes
default:
    @just --list

# Provision VPC + EKS substrate. Pass gpu=true to add the GPU node group.
up gpu="false":
    @echo "⚠️  This provisions real AWS resources that accrue charges. Teardown with: just down"
    AWS_PROFILE={{aws_profile}} tofu -chdir=substrate init -input=false
    AWS_PROFILE={{aws_profile}} tofu -chdir=substrate plan -var gpu={{gpu}}
    AWS_PROFILE={{aws_profile}} tofu -chdir=substrate apply -auto-approve -var gpu={{gpu}}
    aws eks update-kubeconfig \
        --name "$(AWS_PROFILE={{aws_profile}} tofu -chdir=substrate output -raw cluster_name)" \
        --region "$(AWS_PROFILE={{aws_profile}} tofu -chdir=substrate output -raw region)" \
        --profile {{aws_profile}}

# Tear down all substrate resources (state bucket is preserved).
down:
    @echo "Destroying substrate resources. The S3 state bucket is preserved."
    AWS_PROFILE={{aws_profile}} tofu -chdir=substrate destroy -auto-approve

# Show live cluster node state.
status:
    kubectl get nodes -o wide

# Show current OpenCost / estimated spend (M5)
cost:
    @echo "Will show current OpenCost / estimated spend (M5)"

# Drive sustained k6 load and save a summary (M4)
load:
    @echo "Will drive sustained k6 load and save a summary (M4)"

# DRY-RUN preview of changes — no resources created or modified. Pass gpu=true to preview GPU path.
plan gpu="false":
    AWS_PROFILE={{aws_profile}} tofu -chdir=substrate init -input=false
    AWS_PROFILE={{aws_profile}} tofu -chdir=substrate plan -var gpu={{gpu}}

# Run the M0 + M1 acceptance verification harnesses.
test:
    @sh scripts/verify-m0.sh && sh scripts/verify-m1.sh
