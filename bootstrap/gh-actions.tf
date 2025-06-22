variable "cluster_name" {
  type    = string
  default = "cilium-cluster"
}

variable "gh_repo" {
  description = "GitHub repository in the format owner/repo"
  type        = string
  default     = "JohnMonteir0/k8s-with-terraform"
}

data "tls_certificate" "gh_actions_tls" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "gh_actions_oidc" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.gh_actions_tls.certificates[0].sha1_fingerprint]

  tags = {
    Name = "${var.cluster_name}-gh-actions-oidc"
  }
}

resource "aws_iam_role" "gh_actions_role" {
  name = "gh-actions-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Federated : aws_iam_openid_connect_provider.gh_actions_oidc.arn
        },
        Action : "sts:AssumeRoleWithWebIdentity",
        Condition : {
          StringEquals : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.gh_repo}:ref:refs/heads/main",
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_combined" {
  name = "github-actions-combined"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3TerraformBackendAccess",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::terraform-backend-terraformbackends3bucket-cicagxwrw0p9",
          "arn:aws:s3:::terraform-backend-terraformbackends3bucket-cicagxwrw0p9/*"
        ]
      },
      {
        Sid    = "AllowDynamoDBTerraformLocking",
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:058264076061:table/terraform-backend-TerraformBackendDynamoDBTable-1MACMF7VC44EU"
      },
      {
        Sid    = "AllowKmsActions",
        Effect = "Allow",
        Action = [
          "kms:CreateKey",
          "kms:TagResource",
          "kms:DescribeKey",
          "kms:PutKeyPolicy"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowEC2Actions",
        Effect = "Allow",
        Action = [
          "ec2:CreateVpc",
          "ec2:CreateSubnet",
          "ec2:CreateInternetGateway",
          "ec2:CreateRouteTable",
          "ec2:CreateRoute",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:Describe*",
          "ec2:Delete*",
          "ec2:ModifyVpcAttribute",
          "ec2:DescribeVpcAttribute"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowEKSClusterCreateAndManage",
        Effect = "Allow",
        Action = [
          "eks:CreateCluster",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DeleteCluster",
          "eks:TagResource",
          "eks:UntagResource",
          "eks:UpdateClusterVersion",
          "eks:UpdateClusterConfig"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_combined" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = aws_iam_policy.github_actions_combined.arn
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "iam_policy" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "eks_managed" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "kms" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
}

resource "aws_iam_role_policy_attachment" "s3_backend" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "dynamodb_backend" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}