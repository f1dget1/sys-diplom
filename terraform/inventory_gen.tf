# 1. Генерация hosts.ini
resource "local_file" "hosts_ini" {
  content = templatefile("hosts.tpl", {
    bastion_ip   = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
    web_servers  = [
      yandex_compute_instance.nginx-1,
      yandex_compute_instance.nginx-2
    ]
    zabbix_fqdn  = yandex_compute_instance.zabbix.fqdn
    elastic_fqdn = yandex_compute_instance.elasticsearch.fqdn
    kibana_fqdn  = yandex_compute_instance.kibana.fqdn
  })
  filename = "../ansible/hosts.ini"
}

# 2. Генерация all.yml
resource "local_file" "ansible_vars" {
  content = <<EOT
zabbix_server_domain: "${yandex_compute_instance.zabbix.fqdn}"
elasticsearch_domain: "${yandex_compute_instance.elasticsearch.fqdn}"
kibana_domain: "${yandex_compute_instance.kibana.fqdn}"
zabbix_db_password: "${var.zabbix_db_password}"
kibana_password: "${var.kibana_password}"
EOT
  filename = "../ansible/group_vars/all.yml"
}