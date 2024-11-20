resource "aws_ecr_repository" "redis-cluster-repo" {
  name                 = "redis-cluster-image-repository"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
}
