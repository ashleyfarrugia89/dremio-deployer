provider "aws" {
  region = "us-east-1"
}
locals {
  # Centos images for each region
  amis = {
    "us-east-1" = "ami-02eac2c0129f6376b",
    "us-east-2" = "ami-0f2b4fc905b0bd1f1",
    "us-west-1" = "ami-074e2d6769f445be5",
    "us-west-2" = "ami-01ed306a12b7d1c96",
    "ca-central-1" = "ami-033e6106180a626d0",
    "eu-central-1" = "ami-04cf43aca3e6f3de3",
    "eu-west-1" = "ami-0ff760d16d9497662",
    "eu-west-2" = "ami-0eab3a90fc693af19",
    "ap-southeast-1" = "ami-0b4dd9d65556cac22",
    "ap-southeast-2" = "ami-08bd00d7713a39e7d",
    "ap-south-1" = "ami-02e60be79e78fef21",
    "ap-northeast-1" = "ami-045f38c93733dd48d",
    "ap-northeast-2" = "ami-06cf2a72dadf92410",
    "sa-east-1" = "ami-0b8d86d4bf91850af"
  }
  ami = lookup(local.amis, var.region)
  instance_types = {
    "standard" = "m5d.8xlarge",
    "high-memory" = "r5d.4xlarge",
    "high-cpu" = "c5d.18xlarge",
    "high-cache" = "i3.4xlarge"
  }
  instance_type = lookup(local.instance_types, var.engine_type)
  engine_sizes = {
    "small" = 2,
    "medium" = 4,
    "large" = 8,
    "x_large" = 16,
    "xx_large" = 32,
    "xxx_large" = 64
  }
  engine_size = lookup(local.engine_sizes, var.engine_size)
  tags = merge(var.tags, {"dremio_managed" = "true"})
}

# create key pair
resource "tls_private_key" "dremio-managed-key" {
  algorithm = "RSA"
}
resource "aws_key_pair" "deployer" {
  key_name   = "dremio-managed-efs-key"
  public_key = tls_private_key.dremio-managed-key.public_key_openssh
}
resource "null_resource" "dremio_key_pair" {
  provisioner "local-exec" {
    command = "echo  ${tls_private_key.dremio-managed-key.private_key_pem} > dremio-managed.pem"
  }
}

# create ec2 instance
resource "aws_instance" "dremio-managed-coordinator" {
  ami = local.ami
  instance_type = local.instance_type
  iam_instance_profile = var.instance_profile
  subnet_id = var.subnet_id
  provisioner "local-exec" {
    command = "echo ${aws_instance.dremio-managed-coordinator.private_ip} > privateIP.txt"
  }
  tags = local.tags
}

# create EFS
resource "aws_efs_file_system" "dremio-managed-efs" {
  creation_token = "${var.cluster_prefix}-efs"
}

resource "aws_efs_mount_target" "dremio-managed-efs-tgt" {
  file_system_id = aws_efs_file_system.dremio-managed-efs.id
  subnet_id      = var.subnet_id
  security_groups = [var.security_group_id]
}

resource "null_resource" "configure_nfs" {
  depends_on = [aws_efs_mount_target.dremio-managed-efs-tgt]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.dremio-managed-key.private_key_pem
    host     = aws_instance.dremio-managed-coordinator.private_ip
  }
  provisioner = {
    inline = [
      "mkdir ${var.efs_path}",
      "mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0.0.0.0:/ ${var.efs_path}",
      "mkdir -p ${var.efs_path}/log/executor/`hostname -f`",
      "rm -rf ${var.dremio_log_path}",
      "ln -sfn ${var.efs_path}/log/executor/`hostname -f` ${var.dremio_log_path}",
      "chown -R ${var.dremio_userid}:${var.dremio_groupid} ${var.efs_path}/log/executor/`hostname -f`"
    ]
  }
}
