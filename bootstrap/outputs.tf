output "gh_actions_role_arn" {
  value       = aws_iam_role.gh_actions_role.arn
  description = "IAM Role ARN for GitHub Actions"
}