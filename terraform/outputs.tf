output "wordpress_instance_a_public_ip" {
  value = module.wordpress_instance_a.public_ip
}

output "wordpress_instance_b_public_ip" {
  value = module.wordpress_instance_b.public_ip
}

output "mariadb_instance_private_ip" {
  value = module.mariadb_instance.private_ip
}
