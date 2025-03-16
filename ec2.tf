


data "aws_ami" "amzn_linux_2023_latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
output "ami_linux_2023" {
  value = data.aws_ami.amzn_linux_2023_latest.id
}

resource "aws_instance" "test_server" {
  ami                    = data.aws_ami.amzn_linux_2023_latest.id # "ami-053a45fff0a704a47" # <<< "ami-04c913012f8977029"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.test_server.id]

  user_data = templatefile("${path.module}/init-script.sh", {
  })

  associate_public_ip_address = true
  tags                        = var.tags
}

resource "aws_security_group" "test_server" {
  name_prefix = "${local.name_prefix}-test"
  description = "Allow traffic to test server"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
