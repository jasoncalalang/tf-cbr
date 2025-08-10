#!/bin/bash

# Two-Phase Terraform Deployment Script
# Usage: ./deploy.sh [phase1|phase2|both|destroy-phase2|destroy-both]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if terraform.tfvars exists
check_tfvars() {
    local phase_dir=$1
    if [[ ! -f "$phase_dir/terraform.tfvars" ]]; then
        print_error "terraform.tfvars not found in $phase_dir/"
        print_warning "Please copy and customize terraform.tfvars from the example file"
        exit 1
    fi
}

# Function to deploy a phase
deploy_phase() {
    local phase_dir=$1
    local phase_name=$2
    
    print_status "Deploying $phase_name..."
    
    cd "$phase_dir"
    
    # Check for terraform.tfvars
    check_tfvars "."
    
    print_status "Formatting Terraform files..."
    terraform fmt
    
    print_status "Initializing Terraform..."
    terraform init
    
    print_status "Validating configuration..."
    terraform validate
    
    print_status "Creating deployment plan..."
    terraform plan -var-file=terraform.tfvars
    
    echo
    read -p "Do you want to apply this plan? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        print_status "Applying Terraform configuration..."
        terraform apply -var-file=terraform.tfvars -auto-approve
        print_success "$phase_name deployed successfully!"
        
        print_status "Deployment summary:"
        terraform output
    else
        print_warning "Deployment cancelled by user"
        exit 1
    fi
    
    cd ..
}

# Function to destroy a phase
destroy_phase() {
    local phase_dir=$1
    local phase_name=$2
    
    print_warning "Destroying $phase_name..."
    
    cd "$phase_dir"
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        print_error "terraform.tfvars not found in $phase_dir/. Cannot destroy without proper configuration."
        exit 1
    fi
    
    print_status "Creating destruction plan..."
    terraform plan -destroy -var-file=terraform.tfvars
    
    echo
    print_warning "This will DESTROY all resources in $phase_name!"
    read -p "Are you absolutely sure? Type 'yes' to confirm: " confirm
    
    if [[ $confirm == "yes" ]]; then
        print_status "Destroying Terraform resources..."
        terraform destroy -var-file=terraform.tfvars -auto-approve
        print_success "$phase_name destroyed successfully!"
    else
        print_warning "Destruction cancelled by user"
        exit 1
    fi
    
    cd ..
}

# Function to check Phase 1 deployment status
check_phase1_deployed() {
    if [[ ! -f "phase1/terraform.tfstate" ]]; then
        print_error "Phase 1 has not been deployed yet!"
        print_warning "Please deploy Phase 1 first before deploying Phase 2"
        exit 1
    fi
    
    # Check if Phase 1 state file has resources
    if [[ ! -s "phase1/terraform.tfstate" ]]; then
        print_error "Phase 1 state file is empty!"
        print_warning "Please deploy Phase 1 first before deploying Phase 2"
        exit 1
    fi
}

# Function to validate prerequisites
validate_prerequisites() {
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        print_warning "Please install Terraform >= 1.0"
        exit 1
    fi
    
    # Check terraform version
    terraform_version=$(terraform version -json | jq -r '.terraform_version')
    print_status "Using Terraform version: $terraform_version"
    
    # Check if jq is available (optional but useful)
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed. JSON output formatting will be limited."
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  phase1           Deploy Phase 1 (VPC Infrastructure) only"
    echo "  phase2           Deploy Phase 2 (CBR and Test VSI) only"
    echo "  both             Deploy both phases sequentially"
    echo "  destroy-phase2   Destroy Phase 2 resources only"
    echo "  destroy-both     Destroy both phases (Phase 2 first, then Phase 1)"
    echo "  validate         Validate configurations without deploying"
    echo "  status           Show current deployment status"
    echo "  help             Show this help message"
    echo
    echo "Examples:"
    echo "  $0 phase1           # Deploy VPC infrastructure"
    echo "  $0 phase2           # Deploy CBR and test VSI (after Phase 1)"
    echo "  $0 both             # Deploy complete infrastructure"
    echo "  $0 destroy-phase2   # Remove CBR and test components"
}

# Function to show deployment status
show_status() {
    print_status "Deployment Status Check"
    echo
    
    # Check Phase 1
    if [[ -f "phase1/terraform.tfstate" && -s "phase1/terraform.tfstate" ]]; then
        print_success "Phase 1 (VPC Infrastructure): DEPLOYED"
        if command -v jq &> /dev/null; then
            cd phase1
            phase1_summary=$(terraform output -json phase1_summary 2>/dev/null | jq -r '.vpc_name // "N/A"')
            print_status "  VPC Name: $phase1_summary"
            cd ..
        fi
    else
        print_warning "Phase 1 (VPC Infrastructure): NOT DEPLOYED"
    fi
    
    # Check Phase 2
    if [[ -f "phase2/terraform.tfstate" && -s "phase2/terraform.tfstate" ]]; then
        print_success "Phase 2 (CBR and Test VSI): DEPLOYED"
        if command -v jq &> /dev/null; then
            cd phase2
            test_vsi_ip=$(terraform output -json test_vsi_details 2>/dev/null | jq -r '.floating_ip // "N/A"')
            print_status "  Test VSI IP: $test_vsi_ip"
            cd ..
        fi
    else
        print_warning "Phase 2 (CBR and Test VSI): NOT DEPLOYED"
    fi
}

# Function to validate both phases
validate_configurations() {
    print_status "Validating Phase 1 configuration..."
    cd phase1
    check_tfvars "."
    terraform fmt -check=true
    terraform init -backend=false
    terraform validate
    cd ..
    print_success "Phase 1 configuration is valid"
    
    print_status "Validating Phase 2 configuration..."
    cd phase2
    check_tfvars "."
    terraform fmt -check=true
    terraform init -backend=false
    terraform validate
    cd ..
    print_success "Phase 2 configuration is valid"
    
    print_success "All configurations are valid!"
}

# Main script logic
case $1 in
    "phase1")
        validate_prerequisites
        deploy_phase "phase1" "Phase 1 (VPC Infrastructure)"
        ;;
    "phase2")
        validate_prerequisites
        check_phase1_deployed
        deploy_phase "phase2" "Phase 2 (CBR and Test VSI)"
        ;;
    "both")
        validate_prerequisites
        deploy_phase "phase1" "Phase 1 (VPC Infrastructure)"
        deploy_phase "phase2" "Phase 2 (CBR and Test VSI)"
        ;;
    "destroy-phase2")
        validate_prerequisites
        destroy_phase "phase2" "Phase 2 (CBR and Test VSI)"
        ;;
    "destroy-both")
        validate_prerequisites
        destroy_phase "phase2" "Phase 2 (CBR and Test VSI)"
        destroy_phase "phase1" "Phase 1 (VPC Infrastructure)"
        ;;
    "validate")
        validate_prerequisites
        validate_configurations
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    "")
        print_error "No command specified"
        echo
        show_usage
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_usage
        exit 1
        ;;
esac