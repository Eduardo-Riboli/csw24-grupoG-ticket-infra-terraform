provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "teste_t1" {
    ami = "ami-0866a3c8686eaeeba"
    instance_type = "t2.micro"

    vpc_security_group_ids = [aws_security_group.api_access.id]

    key_name = aws_key_pair.my_key_pair.key_name
    tags = {
      Name = "ec2-t1"
    }

      user_data = <<-EOF
        #!/bin/bash
        sudo apt-get update -y
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update -y
        sudo apt-get install -y docker-ce
        sudo usermod -aG docker ubuntu
        sudo systemctl enable docker
        sudo systemctl start docker
    EOF
}

# Criar o repositório ECR
resource "aws_ecr_repository" "myRepository" {
  name                 = "t1-repository"  # Nome do seu repositório
  image_tag_mutability = "MUTABLE"            # Controla se as tags de imagem podem ser alteradas
}


resource "aws_security_group" "api_access" {
  name        = "API-security-group-T1"
  description = "Security group para permitir SSH, HTTP e HTTPS"

  # Regra de entrada para SSH (porta 22)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra de entrada para HTTP (porta 80)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra de entrada para HTTPS (porta 443)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "api port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "pg port"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "pgAdmin port"
    from_port   = 5050
    to_port     = 5050
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra de saída que permite todo o tráfego
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Criação da ssh keypair diretamente no terraform
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-ec2-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

output "private_key_pem" {
  value     = tls_private_key.my_key.private_key_pem
  sensitive = true
}

resource "aws_db_instance" "postgres_instance" {
  identifier         = "rds-t1"
  engine             = "postgres"
  engine_version     = "16.3"  # Versão do PostgreSQL
  instance_class     = "db.t3.micro"
  username           = "postgres"     # Usuário administrador
  password           = "minhasenha123"  # Senha (mude para algo seguro)
  publicly_accessible = true  # Define se será público (use com cuidado)
  skip_final_snapshot = true
  allocated_storage = 20  # Tamanho do disco em GB
  

  vpc_security_group_ids = [aws_security_group.api_access.id]

  # Tags para identificação
  tags = {
    Name = "PostgresRDS"
  }
}