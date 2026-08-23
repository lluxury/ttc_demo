import os

base = r"."

files = [
    ".github/workflows/build-and-deploy.yml",
    "Dockerfile",
    "pom.xml",
    "terraform/common/providers.tf",
    "terraform/common/variables.tf",
    "terraform/common/main.tf",
    "terraform/common/outputs.tf",
    "terraform/dev/providers.tf",
    "terraform/dev/variables.tf",
    "terraform/dev/main.tf",
    "terraform/dev/user_data.sh.tpl",
    "terraform/dev/terraform.tfvars",
    "terraform/uat/providers.tf",
    "terraform/uat/variables.tf",
    "terraform/uat/main.tf",
    "terraform/uat/terraform.tfvars",
    "terraform/prod/providers.tf",
    "terraform/prod/variables.tf",
    "terraform/prod/main.tf",
    "terraform/prod/terraform.tfvars",
    "helm/myapp/Chart.yaml",
    "helm/myapp/values.yaml",
    "helm/myapp/values-uat.yaml",
    "helm/myapp/values-prod.yaml",
    "helm/myapp/templates/deployment.yaml",
    "helm/myapp/templates/service.yaml",
    "helm/myapp/templates/ingress.yaml",
    "helm/myapp/templates/hpa.yaml",
    "gitops-config/uat/argocd-application.yaml",
    "gitops-config/uat/values.yaml",
    "gitops-config/prod/argocd-application.yaml",
    "gitops-config/prod/values.yaml",
]

dirs = [
    "src",
]

for d in dirs:
    os.makedirs(os.path.join(base, d), exist_ok=True)

for f in files:
    path = os.path.join(base, f)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if not os.path.exists(path):
        open(path, "w", encoding="utf-8").close()
        print("create:", f)
    else:
        print("skip :", f)

print("done")