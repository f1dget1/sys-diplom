resource "yandex_vpc_network" "diplom-net" {
  name = "diplom-network"
}

# Публичная подсеть
resource "yandex_vpc_subnet" "public" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom-net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Приватные подсети с привязкой к NAT-шлюзу
resource "yandex_vpc_subnet" "private-a" {
  name           = "private-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom-net.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.nat-rt.id
}

resource "yandex_vpc_subnet" "private-b" {
  name           = "private-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom-net.id
  v4_cidr_blocks = ["192.168.30.0/24"]
  route_table_id = yandex_vpc_route_table.nat-rt.id
}

# NAT для выхода приватных ВМ в интернет (нужен для установки пакетов)
resource "yandex_vpc_gateway" "nat-gw" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat-rt" {
  name       = "nat-route-table"
  network_id = yandex_vpc_network.diplom-net.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gw.id
  }
}

# SECURITY GROUPS
# Используется одна общая группа для внутренних ВМ для упрощения связей Zabbix/ELK
resource "yandex_vpc_security_group" "internal-sg" {
  name       = "internal-sg"
  network_id = yandex_vpc_network.diplom-net.id

  # 1. SSH доступ (изнутри сети и от бастиона)
  ingress {
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion-sg.id
  }

  # 2. Разрешаем всё общение внутри группы (Zabbix-агенты, Elastic-Kibana и т.д.)
  ingress {
    protocol          = "ANY"
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }

  # 3. Входящий трафик от балансировщика (ALB) на Nginx
  ingress {
    protocol          = "TCP"
    port              = 80
    security_group_id = yandex_vpc_security_group.alb-sg.id 
  }

  # 4. Внешний доступ к Zabbix (так как у него есть публичный IP)
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # 5. Внешний доступ к Kibana (порт 5601)
  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "alb-sg" {
  name       = "alb-sg"
  network_id = yandex_vpc_network.diplom-net.id

# Разрешаем всем
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "ANY"
    predefined_target = "loadbalancer_healthchecks" # Обязательно для работы ALB
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "bastion-sg" {
  name       = "bastion-sg"
  network_id = yandex_vpc_network.diplom-net.id

# Доступ к бастиону
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}