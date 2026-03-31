# 1. Elasticsearch
resource "yandex_compute_instance" "elasticsearch" {
  name     = "elasticsearch"
  hostname = "elasticsearch"
  zone     = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4 # Elastic лучше дать больше памяти
    core_fraction = 20
  }

  boot_disk {
    initialize_params { image_id = var.ubuntu-2404 }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private-a.id
    nat       = false
    security_group_ids = [yandex_vpc_security_group.internal-sg.id]
  }

  metadata = {
    user-data = templatefile("meta.yaml", { 
      ssh_key = file("~/.ssh/id_ed25519.pub") 
    })
  }

  scheduling_policy {
    preemptible = false
  }
}