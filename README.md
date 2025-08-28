# Terraform Multi-Cloud Project

This Terraform project demonstrates how to use both AWS and GCP providers to create cloud resources across multiple cloud platforms.

## Features

- **Multi-cloud support**: AWS and GCP providers configured
- **Simple resources**: Creates S3 buckets (AWS) and Storage buckets (GCP)
- **Versioning enabled**: Both buckets have versioning enabled
- **Configurable**: Easy to customize regions, project names, and environments

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS CLI configured or AWS credentials
- GCP CLI configured or service account key file

## Quick Start

1. **Clone and navigate to the project**:
   ```bash
   cd step-dag
   ```

2. **Copy and customize the variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   
   Edit `terraform.tfvars` with your specific values:
   - Update `gcp_project_id` with your actual GCP project ID
   - Uncomment and set AWS credentials if not using AWS CLI
   - Uncomment and set GCP credentials file path if not using gcloud CLI

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Configuration

### AWS Configuration

You can configure AWS credentials in several ways:

1. **Environment variables** (recommended):
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-west-2"
   ```

2. **AWS CLI configuration**:
   ```bash
   aws configure
   ```

3. **Direct in terraform.tfvars** (not recommended for production):
   ```hcl
   aws_access_key = "your-access-key"
   aws_secret_key = "your-secret-key"
   ```

### GCP Configuration

You can configure GCP credentials in several ways:

1. **gcloud CLI** (recommended):
   ```bash
   gcloud auth application-default login
   gcloud config set project your-project-id
   ```

2. **Service account key file**:
   ```bash
   # Download service account key from GCP Console
   # Update terraform.tfvars with the path
   gcp_credentials_file = "path/to/service-account-key.json"
   ```

3. **Environment variable**:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
   ```

## Resources Created

### AWS
- S3 bucket with versioning enabled
- Proper tagging for cost tracking

### GCP
- Cloud Storage bucket with versioning enabled
- Proper labeling for organization

## Customization

### Variables

Key variables you can customize in `terraform.tfvars`:

- `project_name`: Name of your project
- `environment`: Environment (dev, staging, prod)
- `aws_region`: AWS region for resources
- `gcp_region`: GCP region for resources
- `gcp_project_id`: Your GCP project ID

### Adding More Resources

To add more resources:

1. **AWS resources**: Add them to `main.tf` after the existing AWS resources
2. **GCP resources**: Add them to `main.tf` after the existing GCP resources
3. **Variables**: Add new variables to `variables.tf`
4. **Outputs**: Add new outputs to `outputs.tf`

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

## Security Notes

- Never commit `terraform.tfvars` with real credentials
- Use IAM roles and service accounts when possible
- Consider using Terraform Cloud or similar for team collaboration
- Enable MFA for cloud accounts

## Troubleshooting

### Common Issues

1. **Provider authentication errors**: Ensure credentials are properly configured
2. **Region errors**: Verify the specified regions exist and are accessible
3. **Permission errors**: Check IAM roles and service account permissions

### Getting Help

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)

## License

This project is open source and available under the [MIT License](LICENSE).
