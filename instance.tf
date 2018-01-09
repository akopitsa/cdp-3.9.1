resource "aws_key_pair" "my_public_ssh_key" {
  key_name   = "id_rsa1"
  public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}

resource "aws_s3_bucket" "zookeeper-prop" {
  bucket = "my-zookeper-prop-bucket"
  acl    = "private"
  versioning {
    enabled = true
  }
#  depends_on = ["aws_iam_role.zookeeper-iam"]
}
resource "aws_iam_role" "s3-mybucket-role" {
    name = "s3-mybucket-role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "s3-mybucket-role-instanceprofile" {
    name = "s3-mybucket-role"
    role = "${aws_iam_role.s3-mybucket-role.name}"
}

resource "aws_iam_role_policy" "s3-mybucket-role-policy" {
    name = "s3-mybucket-role-policy"
    role = "${aws_iam_role.s3-mybucket-role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:*"
            ],
            "Resource": [
              "arn:aws:s3:::my-zookeper-prop-bucket",
              "arn:aws:s3:::my-zookeper-prop-bucket/*"
            ]
        }
    ]
}
EOF
}



# resource "aws_iam_role" "zookeeper" {
#   name = "zookeeper_role"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "sts:AssumeRole",
#         "s3:AbortMultipartUpload",
#         "s3:DeleteObject",
#         "s3:GetBucketAcl",
#         "s3:GetBucketPolicy",
#         "s3:GetObject",
#         "s3:GetObjectAcl",
#         "s3:ListBucket",
#         "s3:ListBucketMultipartUploads",
#         "s3:ListMultipartUploadParts",
#         "s3:PutObject",
#         "s3:PutObjectAcl"
#       ],
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Resource": [
#         "arn:aws:s3:::my-zookeper-prop-bucket/*",
#         "arn:aws:s3:::my-zookeper-prop-bucket"
#       ],
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }






resource "aws_instance" "zookeeper-server" {
  count             = 3
  ami               = "ami-aa2ea6d0"
  instance_type     = "t2.micro"
  availability_zone = "${var.AVAILABILITY_ZONE}"

  root_block_device {
    volume_size           = "8"
    delete_on_termination = true
  }
  iam_instance_profile = "${aws_iam_instance_profile.s3-mybucket-role-instanceprofile.name}"
  vpc_security_group_ids = ["${aws_security_group.zookeeper-server.id}"]
  key_name               = "${aws_key_pair.my_public_ssh_key.key_name}"

  # connection {
  #   user = "${var.INSTANCE_USERNAME}"
  # }
  depends_on = ["aws_security_group.zookeeper-server"]

  user_data = "${file("server_install.sh")}"

  tags {
    Name = "Zookeeper"
  }
}

resource "aws_security_group" "zookeeper-server" {
  name = "ASG-for-ZOOKEEPER"
  depends_on = ["aws_s3_bucket.zookeeper-prop"]
  ingress {
    from_port   = "${var.EXHIBITOR-PORT}"
    to_port     = "${var.EXHIBITOR-PORT}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "${var.AGENT-PORT}"
    to_port     = "${var.AGENT-PORT}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "${var.SSH-PORT}"
    to_port     = "${var.SSH-PORT}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "${var.CONNECT-PORT}"
    to_port     = "${var.CONNECT-PORT}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "${var.ELECTION-PORT}"
    to_port     = "${var.ELECTION-PORT}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
    Name = "ASG-for-zookeeper-server"
  }
}

# output "puppet_server_dns" {
#   value = "${aws_instance.zookeeper-server.public_dns}"
# }
