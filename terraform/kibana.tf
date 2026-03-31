# Kibana
resource "yandex_compute_instance" "kibana" {
  name     = "kibana"
  hostname = "kibana"
  zone     = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params { image_id = var.ubuntu-2404 }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true # Нужен для доступа к веб-интерфейсу
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