output "bastion_password" {
    value = random_password.bastion_password.result
}

output "private_key_pem" {
    value = tls_private_key.build.private_key_pem
}

output "aks_private_key_pem" {
    value = tls_private_key.aks.private_key_pem
}
