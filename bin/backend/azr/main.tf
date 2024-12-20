resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.cloud_region
  tags = {
    Managed_by = "CI/CD: ${var.workflow}"
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
  tags = {
    Managed_by = "CI/CD: ${var.workflow}"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                            = var.container_name
  storage_account_name            = azurerm_storage_account.tfstate.name
  container_access_type           = "private"
  allow_nested_items_to_be_public = false
}
