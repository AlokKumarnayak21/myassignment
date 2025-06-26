resource "aws_codepipeline" "nginx_pipeline" {
  name     = "nginx-deployment-pipeline"
  role_arn = aws_iam_role.cicd_role.arn  # Updated to use your unified IAM role

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner        # Define in varibles.tf
        Repo       = var.github_repo         # Define in varibles.tf
        Branch     = var.github_branch       # Define in varibles.tf
        OAuthToken = var.github_token        # Define in varibles.tf (use secrets)
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.nginx_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.nginx_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.nginx_group.deployment_group_name

      }
    }
  }
}
