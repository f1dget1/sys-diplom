# providers.tf
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  service_account_key_file = file("~/.authorized_key.json")
  cloud_id                 = "b1gjmkvdkuhpfkvm88rs"
  folder_id                = "b1giio474fdh86ajf1o8"
  zone                     = "ru-central1-a"
}
