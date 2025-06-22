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

### Remote Backend Permissions ###
resource "aws_iam_policy" "github_actions_tf_backend" {
  name = "github-actions-tf-backend-access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3TerraformBackendAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::terraform-backend-terraformbackends3bucket-purx2gafrdxg",
          "arn:aws:s3:::terraform-backend-terraformbackends3bucket-purx2gafrdxg/*"
        ]
      },
      {
        Sid    = "AllowDynamoDBTerraformLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:851725188350:table/terraform-backend-TerraformBackendDynamoDBTable-95EBUWJQAF6E"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_tf_backend" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = aws_iam_policy.github_actions_tf_backend.arn
}

### KMS Key (inline policy only) ###
resource "aws_kms_key" "terraform_backend" {
  description         = "KMS key for Terraform backend"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid: "AllowRootAccountFullAccess",
        Effect: "Allow",
        Principal: {
          AWS: "arn:aws:iam::851725188350:root"
        },
        Action: "kms:*",
        Resource: "*"
      },
      {
        Sid: "AllowGitHubActionsRoleAccess",
        Effect: "Allow",
        Principal: {
          AWS: "arn:aws:iam::851725188350:role/gh-actions-role"
        },
        Action: [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource: "*"
      },
      {
        Sid: "AllowDynamoDBToUseKey",
        Effect: "Allow",
        Principal: {
          Service: "dynamodb.amazonaws.com"
        },
        Action: [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource: "*",
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = "851725188350",
            "kms:ViaService"    = "dynamodb.us-east-1.amazonaws.com"
          }
        }
      }
    ]
  })
}







