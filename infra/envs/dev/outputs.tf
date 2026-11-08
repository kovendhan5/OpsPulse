output "ecr_repository_url" { value = module.ecr.repository_url }
output "node_public_ip" { value = module.k3s_node.public_ip }
output "node_instance_id" { value = module.k3s_node.instance_id }
output "github_ci_role_arn" { value = aws_iam_role.github_ci.arn }
output "ssm_shell_command" {
  value = "aws ssm start-session --target ${module.k3s_node.instance_id} --region ${var.region}"
}
