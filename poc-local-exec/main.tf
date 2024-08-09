# Gerar uma chave privada
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Armazenar a chave privada em um arquivo local
resource "local_file" "tf_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "${path.module}/tf-key.pem"
}

# Criar um par de chaves no AWS EC2
resource "aws_key_pair" "tf_key" {
  key_name   = "tf_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

# Criar um Security Group para permitir SSH e HTTP
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Buscar a AMI mais recente do Amazon Linux 2
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  owners = ["137112412989"]  # ID do proprietário para Amazon Linux AMIs
}

# Criar uma instância EC2 usando a chave privada gerada
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.tf_key.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.rsa.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "${self.private_ip} >> private_ips.txt"
      echo "A instância ${self.id} foi criada com sucesso!"
    EOT
  }

  tags = {
    Name = "teste-poc-tenda"
  }

  depends_on = [aws_security_group.web_sg]
}

# Saída do IP público da instância
output "instance_ip" {
  value = aws_instance.web.public_ip
}
