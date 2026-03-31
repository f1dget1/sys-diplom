# Бастион
resource "yandex_compute_instance" "bastion" {
  name     = "bastion"
  hostname = "bastion"
  zone     = var.zone-a

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params { image_id = var.ubuntu-2404 }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
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