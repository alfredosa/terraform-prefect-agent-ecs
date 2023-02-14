# terraform-prefect-agent-ecs

Replace the variables inside *variable.tf* with your Prefect Workspace ID, Account ID and API Key. 

## Trigger this with 
```console
terraform init
terraform apply secret_key="Secret AWS KEY" -var access_key="ACCESS AWS KEY" 
```

This will create:
1. Prefect Agent running as an ECS task in an ECS cluster
2. S3 Bucket
3. ECR for custom Images
4. VPC + Network configuration + Security Group
5. SSM Secret Key
6. Execution Role and Task Role
