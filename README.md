https://github.com/netology-code/sys-diplom/tree/diplom-zabbix
#  Дипломная работа по профессии «Системный администратор» - Rinat Serkebaev

<details>
<summary>Задание</summary>
Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  - для этого достаточно при создании ВМ указать name=example, hostname=examle !! 

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

Настройка балансировщика:

1. Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

2. Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

3. Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

4. Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

Исходящий доступ в интернет для ВМ внутреннего контура через [NAT-шлюз](https://yandex.cloud/ru/docs/vpc/operations/create-nat-gateway).

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)
</details>


# Описание проекта

В рамках дипломной работы реализована отказоустойчивая инфраструктура в Yandex Cloud, включающая:

- Веб-сервис с балансировкой нагрузки
- Мониторинг (Zabbix)
- Централизованный сбор логов (ELK)
- Резервное копирование
- Bastion host для безопасного доступа

Инфраструктура разворачивается с помощью Terraform и настраивается через Ansible.


# Шаг 1: Подготовка окружения

На этом этапе устанавливается необходимый софт и настраивается доступ к зеркалам ресурсов:

## Установка Terraform (v1.14.7)
- Загрузка бинарного файла

```
wget https://hashicorp-releases.yandexcloud.net/terraform/1.14.7/terraform_1.14.7_linux_amd64.zip
```

- Проверка контрольной суммы

```
wget https://hashicorp-releases.yandexcloud.net/terraform/1.14.7/terraform_1.14.7_SHA256SUMS
sha256sum -c --ignore-missing terraform_1.14.7_SHA256SUMS
```

- Установка в систему

```
sudo unzip terraform_1.14.7_linux_amd64.zip -d /usr/local/bin
terraform version
```
<img src = "img/terraform-install-1.png" width = 100%>


## Установка Ansible
- Установка последней стабильной версии

```
sudo apt update && sudo apt install ansible -y && ansible --version
```
<img src = "img/ansible-install.png" width = 100%>

## meta.yaml. Создание ssh ключа и пользователя rinat

```
ssh-keygen -t ed25519
nano meta.yaml
```
### [meta.yaml](terraform/meta.yaml)
<img src = "img/sshkeygen.png" width = 100%>
<img src = "img/nano-meta-yml.png" width = 100%>


## Конфигурация .terraformrc
- Настройка зеркала провайдера:
  https://terraform-mirror.yandexcloud.net/

```
cat > ~/.terraformrc << EOF
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF
```
```
terraform init
```
<img src = "img/terraform-install-2.png" width = 100%>
<img src = "img/terraform-install-3.png" width = 100%>

# Шаг 2: Описание инфраструктурного кода (Terraform)

В этом разделе описаны все ресурсы, создаваемые в Yandex Cloud.

## Основные конфигурационные файлы

### [network.tf](terraform/network.tf)
- Создает VPC: diplom-network
- Публичная подсеть
- Приватные подсети
- NAT-шлюз и таблица маршрутизации
- Security Groups

### [alb.tf](terraform/alb.tf)
- L7-балансировщик
- target_group
- backend_group с healthcheck (порт 80, 1 сек)
- HTTP-роутер
- Публичный IP
- Вывод данных:
  - IP ALB

### [web_servers.tf](terraform/web_servers.tf)
- ВМ: nginx-1, nginx-2
- Разные зоны доступности
- Без внешних IP

### [zabbix.tf](terraform/zabbix.tf)
- ВМ для мониторинга
- Публичная подсеть

### [elastic.tf](terraform/elastic.tf)
- Elasticsearch ВМ
- Приватная подсеть

### [kibana.tf](terraform/kibana.tf)
- ВМ Kibana
- Публичная подсеть

### [bastion.tf](terraform/bastion.tf)
- Jump-хост

### [inventory_gen.tf](terraform/inventory_gen.tf)
- Генерация hosts.ini и all.yml

### [hosts.tpl](terraform/hosts.tpl)
- Шаблон для генерации `hosts.ini` через Terraform
- Автоматически настраивает ssh проксирование через бастион-хост
- Принимает ключи новых ВМ автоматически (избавляет от ручного подтверждения `yes`)

### [backup.tf](terraform/backup.tf)
- snapshot_schedule
- Ежедневные бэкапы
- Хранение: 7 дней

## Вспомогательные файлы

### [providers.tf](terraform/providers.tf)
- Подключение к Yandex Cloud
- Используется сервисный аккаунт

### [variables.tf](terraform/variables.tf)
- Переменные:
  - ID образов
  - Пароли
  - Зоны

### [outputs.tf](terraform/outputs.tf)
- Вывод данных:
  - IP бастиона
  - IP Zabbix
  - IP Kibana

# Шаг 3: Развертывание инфраструктуры

## Выполнение команд

```
terraform plan
terraform apply
```
## Ввиду массивности вывода были приложены скришноты лишь части вывода terraform apply
<img src = "img/terraform-plan.png" width = 100%>
<img src = "img/apply-1.png" width = 100%>

- Получены публичные IP-адреса:
  - Application Load Balancer
  - Bastion host
  - Zabbix
  - Kibana
<img src = "img/apply-2.png" width = 100%>


## Результат
- Созданы ВМ
<img src = "img/YCVM.png" width = 100%>

- Развернут VPC с разделением на публичную и приватные подсети
<img src = "img/YCNET-1.png" width = 100%>
<img src = "img/YCNET-2.png" width = 100%>

- Приватные ВМ не имеют внешних IP и доступны только через bastion
<img src = "img/YCPR-n1.png" width = 100%>
<img src = "img/YCPR-n2.png" width = 100%>
<img src = "img/YCPR-e.png" width = 100%>

- Настроен NAT-шлюз для выхода приватных ВМ в интернет
<img src = "img/YCNAT-1.png" width = 100%>
<img src = "img/YCNAT-2.png" width = 100%>

- Настроены Security Groups с ограничением доступа по необходимым портам
<img src = "img/YCSEC-1.png" width = 100%>
<img src = "img/YCSEC-2.png" width = 100%>
<img src = "img/YCSEC-3.png" width = 100%>
<img src = "img/YCSEC-4.png" width = 100%>

- Создан L7 Application Load Balancer с healthcheck веб-серверов
<img src = "img/YCALB-1.png" width = 100%>
<img src = "img/YCALB-2.png" width = 100%>
<img src = "img/YCALB-3.png" width = 100%>

- Настроено ежедневное резервное копирование (snapshot) со сроком хранения 7 дней
<img src = "img/YCSNAP-1.png" width = 100%>
<img src = "img/YCSNAP-2.png" width = 100%>

- Карта облачной сети
<img src = "img/YCMAP.png" width = 100%>

- - Автоматически сгенерированы:
  - inventory файл hosts.ini
  - файл переменных all.yml
<img src = "img/ls-ansible.png" width = 100%>




# Шаг 4: Проверка связи


## Проверка
- Используется hosts.ini (сгенерирован автоматически)

Команда:
```
ansible all -m ping
```

## Результат
- Проверка доступности всех внутренних хостов
<img src = "img/ansible-pingpong.png" width = 100%>


# Шаг 5: Описание логики автоматизации (Ansible)

## Проект переведен на ролевую модель. В корне директории ansible/ находятся орекструющие плейбуки, вызывают соответствующие роли

## Архитектура ролей
### Каждая роль в директории roles/ имеет стандартную структуру:

- tasks/main.yml - основная логика
- handlers/main.yml - триггеры для перезапуска сервисов при изменении конфигов
- templates/ - конфигурационные файлы Jinja2

### [main.yml](ansible/main.yml)
- Главный сценарий, запускающий настройку инфраструктуры

### [docker_install.yml](ansible/docker_install.yml)
- Установка Docker на ВМ Elasticsearch и Kibana
- Роль `docker`

### [elastic_deploy.yml](ansible/elastic_deploy.yml)
- Развертка Elasticsearch
- Настройка безопасности и памяти
- Роль `elastic`

### [kibana_deploy.yml](ansible/kibana_deploy.yml)
- Развертка Kibana
- Подключение к Elasticsearch
- Роль `kibana`

### [zabbix_server.yml](ansible/zabbix_server.yml)
- Установка Zabbix-server, PostgreSQL, Создание БД и пользователя, Импорт схемы, настройка при помощи шаблона
- Роль `zabbix`

### [install_nginx.yml](ansible/install_nginx.yml)
- Установка nginx, деплой index.html, настройка конфигурации из шаблона
- Роль `nginx`

### [zabbix_agents.yml](ansible/zabbix_agents.yml)
- Установка Zabbix Agent, настройка конфигурации из шаблона
- Роль `agents`

### [filebeat.yml](ansible/filebeat.yml)
- Установка Filebeat на ВМ nginx, Активация nginx-модуля, настройка конфигурации из шаблона
- Роль `filebeat`

### [ansible.cfg](ansible/ansible.cfg)
- Настройки подключения

### [all.yml](ansible/group_vars/all.yml)
- Сгенерирован автоматически
- Передача динамических данных (FQDN)
- Передача паролей для заббикса и кибаны (variables.tf)


# Шаг 6: Запуск полной конфигурации

## Команда

```
ansible-playbook -i hosts.ini main.yml
```

## Результат
- Установка и настройка всех сервисов
- Полностью автоматизированный процесс
<img src = "img/ansible-playbook-1.png" width = 100%>
<img src = "img/ansible-playbook-2.png" width = 100%>
<img src = "img/ansible-playbook-3.png" width = 100%>
<img src = "img/ansible-playbook-4.png" width = 100%>


# Шаг 7: Проверка и настройка систем

## Проверки

### Сайт
- Доступ через IP ALB
<img src = "img/ALB-curl.png" width = 100%>
<img src = "img/ALB-web1.png" width = 100%>
<img src = "img/ALB-web2.png" width = 100%>

### Zabbix
- Первичная настройка
<img src = "img/ZBXSetup.png" width = 100%>
<img src = "img/ZBXPostgre.png" width = 100%>
<img src = "img/ZBXServerName.png" width = 100%>
<img src = "img/ZBXConf.png" width = 100%>

- Агенты
<img src = "img/ZBXAgents.png" width = 100%>
Был добавлен Web сценарий Nginx * HTTP Check для проверки доступности главной страницы веб-серверов.


- Дашборды:
  - CPU
  - RAM
  - Disk
  - Network
  - HTTP
- Настройка порогов
Пороги были реализованы триггерами.
Ввиду отсутствия нужных триггеров, они были созданы.
<img src = "img/ZBXDashboard-1.png" width = 100%>
<img src = "img/ZBXDashboard-2.png" width = 100%>

<img src = "img/newtrigger-1.png" width = 100%>
<img src = "img/newtrigger-2.png" width = 100%>

### Kibana
- Создание Index Pattern
- Проверка логов от Filebeat
<img src = "img/kibana-welcome.png" width = 100%>
<img src = "img/kibana-index-pattern.png" width = 100%>
<img src = "img/kibana-index-discover.png" width = 100%>


### Отказоустойчивость
- Проверка при отключении одной ВМ
<img src = "img/ALB-test.png" width = 100%>


### Бэкапы
- Проверка snapshot в Yandex Cloud
<img src = "img/YCsnapshots.png" width = 100%>



# Шаг 8: Финальный отчет

## Предоставлно для проверки дипломной работы:
- Публичный IP ALB - 158.160.237.11
- Публичный IP Zabbix - 89.169.151.204
- Публичный IP Kibana - 178.154.224.105
- Пароли - [pass.txt](other/pass.txt)



## Итог
- Инфраструктура развернута
- Сервисы функционируют корректно
