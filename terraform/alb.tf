# Балансировщик 
# 1. Группа ресурсов (куда отправлять трафик)
resource "yandex_alb_target_group" "web-target-group" {
  name      = "web-target-group"

  target {
    subnet_id = yandex_vpc_subnet.private-a.id
    ip_address   = yandex_compute_instance.nginx-1.network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.private-b.id
    ip_address   = yandex_compute_instance.nginx-2.network_interface.0.ip_address
  }
}

# 2. Backend (проверка, живы ли сервера)
resource "yandex_alb_backend_group" "web-backend-group" {
  name      = "web-backend-group"

  http_backend {
    name                   = "backend-1"
    weight                 = 1
    port                   = 80
    target_group_ids       = [yandex_alb_target_group.web-target-group.id]
    load_balancing_config {
      panic_threshold      = 50
    }    
    healthcheck {
      timeout              = "1s" 
      interval             = "1s" # Для учебных целей установил 1 секунду, так удобнее проверять работу балансировщика
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

# 3. HTTP-роутер
resource "yandex_alb_http_router" "web-router" {
  name      = "web-router"
}

resource "yandex_alb_virtual_host" "web-virtual-host" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web-router.id
  route {
    name = "route-1"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web-backend-group.id
        timeout          = "3s"
      }
    }
  }
}

# 4. Сам Балансировщик
resource "yandex_alb_load_balancer" "web-balancer" {
  name        = "web-balancer"
  network_id  = yandex_vpc_network.diplom-net.id
  security_group_ids = [yandex_vpc_security_group.alb-sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public.id
    }
  }

  listener {
    name = "listener-1"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.web-router.id
      }
    }
  }
}

# 5. Вывод IP балансировщика
output "alb_external_ip" {
  value = yandex_alb_load_balancer.web-balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}