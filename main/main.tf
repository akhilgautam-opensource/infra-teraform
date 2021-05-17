# provider setup

provider "aws" {
    region = "us-east-1"
    access_key=""
    secret_key=""
}
variable "sunbet_cidr" {
  description = "value"
    
}
# resouce "<provider>_<resource>"" "name"{
#     key value pair 
# }

resource "aws_vpc" "ProjectVPC" {
  cidr_block = "10.0.0.0/16"
  tags ={
      Name = "firstVPC"
  }
}

resource "aws_security_group" "subnet" {
    vpc_id = aws_vpc.ProjectVPC.vpc_id
    cidr_blocks = var.sunbet_cidr
    availability_zone="us-east-1a"
    tags ={
        Name="first_subnet"
    }
}

resource "aws_internet_gateway" "IG" {
  vpc_id = aws_vpc.ProjectVPC.vpc_id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.ProjectVPC.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IG.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.IG.id
  }

  tags = {
    Name = "mytable"
  }
}

resource "aws_route_table_association" "association" {
  subnet_id      = aws_security_group.subnet.id
  route_table_id = aws_route_table.route_table.id

}

resource "aws_security_group" "webserversecuritygroup" {
  name        = "webserversecuritygroup"
  description = "Allow http,https,SSH inbound traffic"
  vpc_id      = aws_vpc.ProjectVPC.id

  ingress {
    description      = "Https trafic from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "Http trafic from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "SSH trafic from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web_forIS server"
  }
}

resource "aws_network_interface" "first_networkinterface" {
  subnet_id       = aws_security_group.subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.webserversecuritygroup.id]

}


resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.first_networkinterface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.IG
    
  ]

}


resouce "aws_EC2" "Servers"{
        vpc_id=aws_vpc.ProjectVPC.vpc_id
    ami=""
    instance_type="t2.micro"
    availability_zone="us-east-1a"
    key_main="main.key"

    network_interface{
      device_index=0
      network_interface=aws_network_interface.first_networkinterface.id
    }
     tags = {
    Name = "FirstServerbyTeraform"
  }

  user_data =<<-EOF
               #!/bin/bash
               sudo apt update -y
               sudo apt install apache2 -y
               sudo systemct1 start apache2
               sudo bash -c 'echo your very first web server > /var/www/html/index.html'
               EOF
               


}