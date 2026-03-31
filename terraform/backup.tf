# Создание снапшотов
resource "yandex_compute_snapshot_schedule" "daily" {
  name = "daily-backup"

  schedule_policy {
    expression = "20 21 * * *" 
  }

  retention_period = "168h"

  snapshot_spec {
    description = "Daily backup for diploma"
  }

  disk_ids = [
    yandex_compute_instance.nginx-1.boot_disk.0.disk_id,
    yandex_compute_instance.nginx-2.boot_disk.0.disk_id,
    yandex_compute_instance.zabbix.boot_disk.0.disk_id,
    yandex_compute_instance.elasticsearch.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id,
    yandex_compute_instance.bastion.boot_disk.0.disk_id
  ]
}
