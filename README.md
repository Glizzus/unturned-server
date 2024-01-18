# Unturned Server

This is a repository containing the necessecities to run an Unturned server on Linux in the cloud.
Terraform is used to provision the server and Ansible is used to configure it.

## Requirements
- Terraform
- Ansible
- DigitalOcean account (with API key)

## Usage

### Terraform

1. Create a file called `terraform.tfvars` in `terraform/`.
2. Add the following variables to the file:
- `do_token` - Your DigitalOcean API key
- `private_key` - The path to your private key
- `public_key` - The path to your public key

3. Run `terraform init` to initialize the Terraform project.
4. Run `terraform apply` to provision the server.

### Ansible

1. Create a file called `custom.yml` in `ansible/vars/`. Refer to `ansible/vars/custom.yml.example`.
2. Run `ansible-playbook -i <inventory> playbook.yml` to configure the server.
