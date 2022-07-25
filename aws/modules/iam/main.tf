provider "aws" {
  region = "us-east-1"
}
resource "aws_iam_policy" "dremio_managed_iam_policy" {
  name = "${var.cluster_prefix}-iam-policy"
  description = "IAM permissions for Dremio in AWS"
  policy = jsonencode(
          {
            "Version" : "2012-10-17",
            "Statement" : [
              {
                "Effect" : "Allow",
                "Action" : "ec2:DeleteVolume",
                "Resource" : "arn:aws:ec2:*:*:volume/*",
                "Condition" : {
                  "StringEquals" : {
                    "ec2:ResourceTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "ec2:AttachVolume",
                  "ec2:DetachVolume",
                  "ec2:ReplaceIamInstanceProfileAssociation",
                  "ec2:TerminateInstances"
                ],
                "Resource" : [
                  "arn:aws:ec2:*:*:instance/*",
                  "arn:aws:ec2:*:*:volume/*"
                ],
                "Condition" : {
                  "StringEquals" : {
                    "ec2:ResourceTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:DeleteSnapshot",
                "Resource" : "arn:aws:ec2:*::snapshot/*",
                "Condition" : {
                  "StringEquals" : {
                    "ec2:ResourceTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "elasticfilesystem:CreateMountTarget",
                  "elasticfilesystem:DeleteFileSystem",
                  "elasticfilesystem:DeleteMountTarget"
                ],
                "Resource" : "arn:aws:elasticfilesystem:*:*:file-system/*",
                "Condition" : {
                  "StringEquals" : {
                    "aws:ResourceTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:CreateTags",
                "Resource" : "arn:aws:ec2:*:*:volume/*",
                "Condition" : {
                  "StringEquals" : {
                    "ec2:ResourceTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "elasticfilesystem:CreateFileSystem",
                "Resource" : "*",
                "Condition" : {
                  "StringEquals" : {
                    "aws:RequestTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:CreateVolume",
                "Resource" : "arn:aws:ec2:*:*:volume/*",
                "Condition" : {
                  "StringEquals" : {
                    "aws:RequestTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:RunInstances",
                "Resource" : [
                  "arn:aws:ec2:*:*:volume/*",
                  "arn:aws:ec2:*:*:instance/*"
                ],
                "Condition" : {
                  "StringEquals" : {
                    "aws:RequestTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:RunInstances",
                "Resource" : [
                  "arn:aws:ec2:*::image/*",
                  "arn:aws:ec2:*:*:network-interface/*",
                  "arn:aws:ec2:*:*:security-group/*",
                  "arn:aws:ec2:*:*:subnet/*",
                  "arn:aws:ec2:*:*:key-pair/*",
                  "arn:aws:ec2:*:*:placement-group/*"
                ]
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:CreateSnapshot",
                "Resource" : "arn:aws:ec2:*::snapshot/*",
                "Condition" : {
                  "StringEquals" : {
                    "aws:RequestTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:CreateSnapshot",
                "Resource" : "arn:aws:ec2:*:*:volume/*",
                "Condition" : {
                  "StringEquals" : {
                    "ec2:ResourceTag/dremio_managed" : "true"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:CreateTags",
                "Resource" : "arn:aws:ec2:*:*:volume/*",
                "Condition" : {
                  "StringEquals" : {
                    "ec2:CreateAction" : "CreateVolume"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:CreateTags",
                "Resource" : "arn:aws:ec2:*::snapshot/*",
                "Condition" : {
                  "StringEquals" : {
                    "ec2:CreateAction" : "CreateSnapshot"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:CreateTags",
                "Resource" : [
                  "arn:aws:ec2:*:*:instance/*",
                  "arn:aws:ec2:*:*:volume/*"
                ],
                "Condition" : {
                  "StringEquals" : {
                    "ec2:CreateAction" : "RunInstances"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : "ec2:CreateTags",
                "Resource" : "arn:aws:ec2:*:*:placement-group/*",
                "Condition" : {
                  "StringEquals" : {
                    "ec2:CreateAction" : "CreatePlacementGroup"
                  }
                }
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "ec2:CreateNetworkInterface",
                  "ec2:DeleteNetworkInterface",
                  "ec2:CreatePlacementGroup",
                  "ec2:DeletePlacementGroup"
                ],
                "Resource" : "*"
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "ec2:DescribeAvailabilityZones",
                  "ec2:DescribeIamInstanceProfileAssociations",
                  "ec2:DescribeImages",
                  "ec2:DescribeInstances",
                  "ec2:DescribeInstanceStatus",
                  "ec2:DescribeNetworkInterfaces",
                  "ec2:DescribeNetworkInterfaceAttribute",
                  "ec2:DescribePlacementGroups",
                  "ec2:DescribeSnapshots",
                  "ec2:DescribeSubnets",
                  "ec2:DescribeTags",
                  "ec2:DescribeVolumes"
                ],
                "Resource" : "*"
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "elasticfilesystem:DescribeFileSystems",
                  "elasticfilesystem:DescribeMountTargets",
                  "elasticfilesystem:DescribeMountTargetSecurityGroups"
                ],
                "Resource" : "arn:aws:elasticfilesystem:*:*:file-system/*"
              },
              {
                "Effect" : "Allow",
                "Action" : "iam:GetInstanceProfile",
                "Resource" : "arn:aws:iam::*:instance-profile/*"
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "iam:GetPolicy",
                  "iam:GetPolicyVersion"
                ],
                "Resource" : "arn:aws:iam::*:policy/*"
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "iam:GetRolePolicy",
                  "iam:ListAttachedRolePolicies",
                  "iam:ListRolePolicies"
                ],
                "Resource" : "arn:aws:iam::*:role/*"
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "iam:SimulateCustomPolicy",
                  "s3:HeadBucket",
                  "s3:ListAllMyBuckets"
                ],
                "Resource" : "*"
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "s3:DeleteObject",
                  "s3:GetObject",
                  "s3:PutObject"
                ],
                "Resource" : "arn:aws:s3:::dremio-me-*/*"
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "s3:CreateBucket",
                  "s3:DeleteBucket",
                  "s3:GetBucketLocation",
                  "s3:ListBucket",
                  "s3:PutBucketTagging"
                ],
                "Resource" : "arn:aws:s3:::dremio-me-*"
              },
              {
                "Effect" : "Allow",
                "Action" : [
                  "s3:ListBucket",
                  "s3:GetBucketLocation"
                ],
                "Resource" : [
                  "arn:aws:s3:::ap-southwest-1.examples.dremio.com",
                  "arn:aws:s3:::eu-west-1.examples.dremio.com",
                  "arn:aws:s3:::us-east-1.examples.dremio.com",
                  "arn:aws:s3:::us-west-1.examples.dremio.com",
                  "arn:aws:s3:::us-west-2.examples.dremio.com"
                ]
              },
              {
                "Effect" : "Allow",
                "Action" : "s3:GetObject",
                "Resource" : [
                  "arn:aws:s3:::ap-southwest-1.examples.dremio.com/*",
                  "arn:aws:s3:::eu-west-1.examples.dremio.com/*",
                  "arn:aws:s3:::us-east-1.examples.dremio.com/*",
                  "arn:aws:s3:::us-west-1.examples.dremio.com/*",
                  "arn:aws:s3:::us-west-2.examples.dremio.com/*"
                ]
              }
            ]
          }
  )
}
resource "aws_iam_role" "dremio_managed_iam_role" {
  name               = "${var.cluster_prefix}-iam-role"
  assume_role_policy = aws_iam_policy.dremio_managed_iam_policy
}
resource "aws_iam_policy" "dremio_managed_iam_policy_enhanced" {
  name               = "${var.cluster_prefix}-iam-role-enhanced"
  policy             = jsonencode(
          {
            "Version" : "2012-10-17",
            "Statement" : [
              {
                "Effect" : "Allow",
                "Action" : [
                  "iam:GetRole",
                  "iam:PassRole"
                ],
                "Resource" : aws_iam_role.dremio_managed_iam_role.arn
              }
            ]
          }
  )
}
resource "aws_iam_role_policy_attachment" "dremio_managed_iam_policy_attachment" {
  name               = "${var.cluster_prefix}-enhanced-attch"
  policy_arn         = aws_iam_policy.dremio_managed_iam_policy_enhanced.arn
  role               = aws_iam_role.dremio_managed_iam_role.name
}
resource "aws_iam_instance_profile" "dremio-managed-instance-prof" {
  name = "${var.cluster_prefix}-instance-prof"
  role = aws_iam_role.dremio_managed_iam_role.name
}

