resource "aws_codebuild_project" "nginx_build" {
  name          = "nginx-build"
  description   = "Build project for Nginx deployment"
  service_role  = aws_iam_role.cicd_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}
