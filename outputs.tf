output "deployed_apps" {
  description = "Map of application names to their live public IP addresses"
  value = {
    for app_name, instance in aws_instance.app_servers : app_name => instance.public_ip
  }
}
