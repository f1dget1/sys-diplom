resource "yandex_compute_instance" "nginx-1" {
  name     = "nginx-1"
  hostname = "nginx-1"
  zone     = var.zone-a # Зона А

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params { image_id = var.ubuntu-2404 }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private-a.id # Приватная подсеть А
    nat       = false
    security_group_ids = [yandex_vpc_security_group.internal-sg.id] # Привязка группы
  }

  metadata = {
    user-data = templatefile("meta.yaml", { 
      ssh_key = file("~/.ssh/id_ed25519.pub") 
    })
  }

  scheduling_policy {
    preemptible = false # Прерываемая
  }
}

resource "yandex_compute_instance" "nginx-2" {
  name     = "nginx-2"
  hostname = "nginx-2"
  zone     = var.zone-b # Зона B

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params { image_id = var.ubuntu-2404 }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private-b.id # Приватная подсеть B
    nat       = false
    security_group_ids = [yandex_vpc_security_group.internal-sg.id] # Привязка группы
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