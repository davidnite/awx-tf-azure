# AWX in Azure via Terraform

1. Create a service principal and store the required values in the variables.tf file
2. Update the variables.tf file with valid data for your environment
3. Generate an SSH keypair and store the public key in the SSH variable
4. Update the state.tf file with a valid storage account
5. AWX will be publicly available, so update the NSG as necessary