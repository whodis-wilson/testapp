# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
  shared_credentials_file = "${var.shared_credentials_file}"
  profile = "${var.shared_credentials_profile}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "aod-testapp" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "aod-testapp" {
  vpc_id = "${aws_vpc.aod-testapp.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.aod-testapp.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.aod-testapp.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "aod-testapp" {
  vpc_id                  = "${aws_vpc.aod-testapp.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "testapp_elb"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.aod-testapp.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our aod-testapp security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "aod-testapp" {
  name        = "testapp"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.aod-testapp.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "testapp-elb"

  subnets         = ["${aws_subnet.aod-testapp.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.web.id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "tls_private_key" "webkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.webkey.public_key_openssh}"
  //public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "web" {

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "aws"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.aod-testapp.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.aod-testapp.id}"

  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ec2-user"
    private_key = "${tls_private_key.webkey.private_key_pem}"

    # The connection will use the local SSH agent for authentication.
    host = self.public_ip
  }

  # We run a remote provisioner on the instance after creating it.
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "mkdir -p /home/ec2-user/testapp"
    ]
  }
  provisioner "file" {
    source = "../"
    destination = "/home/ec2-user/testapp"
  }
  provisioner "remote-exec" {
    inline = [
      "cd ~/testapp",
      "docker build --tag=testapp .",
      "docker run -d -p 8080:8080 testapp",
    ]    
  }
}