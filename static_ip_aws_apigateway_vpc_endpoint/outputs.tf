
output "rest_api_id" {
  value = aws_api_gateway_rest_api.rest_api.id
}

output "rest_api_arn" {
  value = aws_api_gateway_rest_api.rest_api.arn
}

output "rest_api_name" {
  value = aws_api_gateway_rest_api.rest_api.name
}

output "rest_api_url" {
  value = "${aws_api_gateway_deployment.rest_api_deployment.invoke_url}${aws_api_gateway_stage.rest_api_stage.stage_name}${aws_api_gateway_resource.rest_api_resource.path}"
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets_id" {
  value = [aws_subnet.public_subnet.*.id]
}

output "private_subnets_id" {
  value = [aws_subnet.private_subnet.*.id]
}

output "security_groups_ids" {
  value = [aws_security_group.security_group.id]
}

output "public_route_table" {
  value = aws_route_table.public.id
}
