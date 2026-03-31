variable "ubuntu-2404" {
  default = "fd8jjccig145ofgp5b9u"
}

variable "username" {
  default = "rinat"
}

variable "zone-a" {
  default = "ru-central1-a"
}

variable "zone-b" {
  default = "ru-central1-b"
}

variable "zabbix_db_password" {
  description = "Password for Zabbix PostgreSQL database"
  default     = "ZabbixInitInit291192!"
  sensitive   = true
}

variable "kibana_password" {
  description = "Password for Elastic/Kibana auth"
  default     = "KibanaInitInit291192!"
  sensitive   = true
}