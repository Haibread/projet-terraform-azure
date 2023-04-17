# projet-terraform-azure

Prérequis :

Terraform
azure-cli
Se connecter avec azure-cli login
terraform plan -var-file=demo.tfvars
terraform apply -var-file=demo.tfvars
terraform destroy -var-file=demo.tfvars

## Problèmes rencontrés

- Private endoint pour le app service + la zone dns privée
- Comment changer le path prefix pour wordpress
- Comment générer les règles de fw pour autoriser l'app service à aller vers la BDD
- Comment faire un template du cloudinit pour bootstapper wordpress
- Comment configurer l'application gateway avec les différents backends et l'url_path_map
