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