output "private_subnet1_id" {
  value = aws_subnet.private1.id
}

output "private_subnet2_id" {
  value = aws_subnet.private2.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "ecr_repository" {
  value = aws_ecr_repository.redis-cluster-repo.repository_url
}

output "vpc_main_cidr" {
  value = aws_vpc.main.cidr_block
}
