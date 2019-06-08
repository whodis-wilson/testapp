variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/id_rsa.pub
DESCRIPTION
default = "~/.ssh/id_rsa.pub"
}
variable "private_key_path" {
  description = "Private key to the public key specified"
  default = "~/.ssh/id_rsa"
}
variable "key_name" {
  description = "Public SSH key for instance sshd auth"
  default = "aws"
}

variable "aws_region" {
  description = "AWS region."
  default     = "us-west-2"
}

# Current amazon linux 2
variable "aws_amis" {
  default = {
    us-west-2 = "ami-0cb72367e98845d43"
  }
}

variable "shared_credentials_file" {
  default = "~/.aws/credentials"
  description = "AWS credentials file"
}

variable "shared_credentials_profile" {
  description = "AWS credentials profile"
}