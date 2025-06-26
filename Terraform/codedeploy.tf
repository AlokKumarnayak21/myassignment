resource "aws_codedeploy_app" "nginx_app" {
  name = "nginx-codedeploy-app"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "nginx_group" {
  app_name              = aws_codedeploy_app.nginx_app.name
  deployment_group_name = "nginx-deploy-group"
  service_role_arn      = aws_iam_role.cicd_role.arn

  deployment_style {
    deployment_type = "IN_PLACE"
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "nginx-ec2-instance"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
