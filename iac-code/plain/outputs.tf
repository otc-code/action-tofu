output "Name_Prefix" {
  value       = module.common.name_prefix
  description = "The prefix for the name of the resources"
}

output "text" {
  value       = "Hello, World!"
  description = "Hello, World!"
}

output "password" {
  value       = random_string.random.result
  description = "Random Password"
}