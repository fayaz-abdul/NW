output "vnet_name" {
    value = "${azurerm_virtual_network.network.name}"
}

output "aks_subnet_id" {
    value = "${azurerm_subnet.aks_subnet.id}"
}

output "postgres_subnet_id" {
    value = "${azurerm_subnet.postgres_subnet.id}"
}

output "elastic_subnet_id" {
    value = "${azurerm_subnet.elastic_subnet.id}"
}
