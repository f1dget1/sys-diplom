[all:vars]
ansible_user=rinat
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -o StrictHostKeyChecking=accept-new rinat@${bastion_ip}" -o StrictHostKeyChecking=accept-new'

[nginx-web]
%{ for vm in web_servers ~}
${vm.fqdn}
%{ endfor ~}

[zabbix]
${zabbix_fqdn}

[elasticsearch]
${elastic_fqdn}

[kibana]
${kibana_fqdn}
