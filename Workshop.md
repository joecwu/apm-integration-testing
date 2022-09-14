# Elastic Observability 實作體驗營 @ DevOpsDays Taipei 2022

:::info
**本頁面網址：** https://hackmd.io/@estraining/DevOpsDaysTaipei2022
**講者：** [喬叔 (Joe Wu)](https://training.onedoggo.com/about-me)
**Facebook 粉絲頁：** [喬叔 - Elastic Stack 技術交流](https://www.facebook.com/Joe.ElasticStack/)
:::

## 行前準備

### 操作電腦需求

- 最少 16GB 以上的 RAM
- 最少 50GB 以上的 Disk Space
- MacOS, Linux, Windows 皆可，但請不要用太舊的作業系統

### 準備執行環境

請先在電腦中安裝以下所需的執行環境：

- Docker
- Docker Compose ([安裝說明](https://docs.docker.com/compose/install/))
- Python3 ([安裝說明](https://github.com/elastic/apm-integration-testing#python-3))
- Git (會簡單的 `git clone`, `git pull`, `git checkout` 即可。)

### 準備好 Docker Images

這次的工作坊，使用的是 Elastic 在 GitHub 所提供的 [apm-integration-testing](https://github.com/elastic/apm-integration-testing) 開源專案。

因為在操作時會需要 build Docker image 以及下載一些 Elastic Stack 的 Docker images，為了避免工作坊的時間被佔用在處理 build & download，建議請大家先完成以下的步驟。

:::danger
:exclamation:請注意，喬叔有特別為了這次工作坊進行一些準備，所以請直接到喬叔 fork 出來的 GitHub 專案進行下載 [https://github.com/joecwu/apm-integration-testing/](https://github.com/joecwu/apm-integration-testing/)，不要下載到 Elastic 官方版的哦！
:::

1. 取得 apm-integration-testing 的檔案。

可使用 `git clone` 的指令，或是直接[下載 Zip 壓縮檔](https://github.com/joecwu/apm-integration-testing/archive/refs/heads/main.zip)。
```
git clone https://github.com/joecwu/apm-integration-testing.git
```

2. 在專案的根路徑下，執行以下 `compose.py build` 的指令，以建立及下載所需要使用到的 Docker images：

Mac or Linux：
```
./scripts/compose.py build --release --with-opbeans-java --with-opbeans-ruby --with-opbeans-python --with-opbeans-go --with-opbeans-node --with-opbeans-rum --with-filebeat --with-metricbeat --with-heartbeat 8.4.1
```
Windows：
```
python .\scripts\compose.py build --release --with-opbeans-java --with-opbeans-ruby --with-opbeans-python --with-opbeans-go --with-opbeans-node --with-opbeans-rum --with-filebeat --with-metricbeat --with-heartbeat 8.4.1
```


3. 確認 Docker Images 已被成功建置及下載。

使用 `docker images` 指令，確認有存在下列 Docker Images.

![](https://i.imgur.com/wSSnE7D.png)


## Elastic APM Integration Test 簡介

[APM Integration Testing](https://github.com/elastic/apm-integration-testing) 是一個公開在 GitHub 的開放原始碼的專案，這個專案主要語言是用 Python 撰寫，並且使用 Docker 來運作 Elastic Stack 的各種服務以及 opbeans 這個 Demo 專用的庫存管理系統，讓我們能夠擁有一個 Elastic APM 所需要執行的情境，並且能夠將當中的某些元件替換成真實運作的版本，可以協助開發人員進行 debug，或是協助整合測試 (Integration Test) 所需使用的複雜的環境。

### 包含的角色

以下幾種角色，是 APM Integration Testing 的 Docker Containers 運作起來時，裡面有的角色：

- Elastic Stack
  - Elasticsearch
  - Kibana
  - APM Server
  - Heartbeat
  - Filebeat
  - Metricbeat
  - Packetbeat
- opbeans 庫存管理系統的各種語言版本的實作，並且埋入 APM Agent
  - opbeans-go
  - opbeans-java
  - opbeans-ruby
  - opbeans-dotnet
  - opbeans-node
  - opbeans-python
  - opbeans-php
- opbeans 所使用到的 Database 或是 Cache 等服務
  - PostgreSQL
  - Redis
- 針對 opbeans 庫存管理的系統，使用 [apm-agent-rum-js](https://github.com/elastic/apm-agent-rum-js)，實作 Real User Monitoring
  - opbeans-rum
- 自動模擬存取流量的 opbeans-load-generator
- 專門製造錯誤情況發生，讓壓測能更擬真的 Dyno. (僅支援 opbeans-python)

### 運作示範

下圖是 Kibana > Observability > Trace > Service Map 的截圖。

:::warning
請留意，每個 opbeans 即是一個完整的 web 專案，本身就可以獨立運作，但是當 apm-integration-testing 透過 docker-compose 啟動時，如果同時執行超過一種以上的 `opbeans-XXX`，會在執行時隨機存取其他 `opbeans-XXX`，創造出 service 與 service 之間互相溝通的存取，以模擬多層次或是分散式架構系統的運作情境。
:::

![18-apm-tools-service-map](https://i.imgur.com/bR93Z78.png)


## 任務一：將 apm-integration-test 運作起來

### 1. 準備執行環境

請確認電腦已安裝好下列必要的執行環境：

- Docker
- Docker Compose ([安裝說明](https://docs.docker.com/compose/install/))
- Python3 ([安裝說明](https://github.com/joecwu/apm-integration-testing#python-3))

### 2. 安裝指令

透過執行 `compose.py start` 產生並執行 `docker-compose.yml`。
```
./scripts/compose.py start --release --with-opbeans-java --with-opbeans-ruby --with-opbeans-python --with-opbeans-go --with-opbeans-node --with-opbeans-rum --with-filebeat --with-metricbeat --with-heartbeat 8.4.1
```

:::warning
如果系統資源不足，跑不動太多的 Containers 的話，可以減少一些 `--with-opbeans-{XXX}`。
建議最少要啟動 `opbeans-node` 及 `opbeans-rum`。

例如：
```
./scripts/compose.py start --release --with-opbeans-python --with-opbeans-go --with-opbeans-node --with-opbeans-rum --with-filebeat --with-metricbeat --with-heartbeat 8.4.1
```
:::

:::info
由於 `opbeans-dotnet` .Net 的版本在 Apple M1 系列 CPU 建置時可能會有問題，所以我們這次直接略過不使用 `opbeans-dotnet` 版本，若你是 Windows 的環境，且硬體資源充足，想嘗試的話，還是可以加入 `--with-opbeans-dotnet`
:::

### 3. 確認安裝完成

使用 `docker-compose ps -a` 或是 `docker ps -a` 查看執行中的 containers。

### 4. 登入 Kibana

預設管理者帳號：`admin`
預設密碼：`changeme`

![](https://i.imgur.com/dfaZlLt.png)

### 5. 查看 Kibana > Stack Monitoring

進入 [Kibana > Stack Monitoring](http://localhost:5601/app/monitoring)，可以成功查看 Elasticsearch Cluster 正常的運作，同時也有 Kibana 與 3 個 beats 正在運作中。

![](https://i.imgur.com/bcEG3uS.png)

## 任務二：收集 Opbeans 各服務所產生的 Logs

### 1. 設定 `filebeat.yml`

修改 `./docker/filebeat/filebeat.yml` 

在 **## autodiscover** 的區塊裡，填加以下的設定。

```yaml
filebeat.autodiscover:
  providers:
    - type: docker
      templates:
        - condition:
            contains:
              docker.container.name: "opbeans-"
          config:
            - type: container
              paths:
                - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
              include_lines: ['^{']
              tail_files: true
              processors:
              - add_tags:
                  tags: [json]
                  target: "parser_type"
              - decode_json_fields:
                  fields:
                    - message
                  target: ""
                  overwrite_keys: true
                  add_error_key: true
              - drop_fields:
                  fields:
                    - service
                    - event
                    - url
                    - error
              - copy_fields:
                  fields:
                  - from: container.name
                    to: event.dataset
                  fail_on_error: false
                  ignore_missing: true
              fields_under_root: true
        - condition:
            contains:
              docker.container.name: "opbeans-"
          config:
            - type: container
              paths:
                - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
              tail_files: true
              multiline.pattern: '^[[:blank:]]'
              multiline.negate: false
              multiline.match: after
              exclude_lines: ['^{']
              processors:
              - add_tags:
                  tags: [no_json]
                  target: "parser_type"
              - copy_fields:
                  fields:
                  - from: container.name
                    to: event.dataset
                  fail_on_error: false
                  ignore_missing: true
        - condition:
            contains:
              docker.container.name: "kibana"
          config:
            - type: container
              paths:
                - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
              tail_files: true
              json.add_error_key: true
              json.overwrite_keys: true
              json.keys_under_root: true
              processors:
              - copy_fields:
                  fields:
                  - from: container.name
                    to: event.dataset
                  fail_on_error: false
                  ignore_missing: true
        - condition:
            contains:
              docker.container.name: "elasticsearch"
          config:
            - type: container
              paths:
                - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
              tail_files: true
              json.add_error_key: true
              json.overwrite_keys: true
              json.keys_under_root: true
              processors:
              - copy_fields:
                  fields:
                  - from: container.name
                    to: event.dataset
                  fail_on_error: false
                  ignore_missing: true
        - condition:
            contains:
              docker.container.name: "metricbeat"
          config:
            - type: container
              paths:
                - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
              tail_files: true
              json.add_error_key: true
              json.overwrite_keys: true
              json.keys_under_root: true
              processors:
              - copy_fields:
                  fields:
                  - from: container.name
                    to: event.dataset
                  fail_on_error: false
                  ignore_missing: true
        - condition:
            contains:
              docker.container.name: "heartbeat"
          config:
            - type: container
              paths:
                - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
              tail_files: true
              json.add_error_key: true
              json.overwrite_keys: true
              json.keys_under_root: true
              processors:
              - copy_fields:
                  fields:
                  - from: container.name
                    to: event.dataset
                  fail_on_error: false
                  ignore_missing: true
        - condition:
            contains:
              docker.container.name: "filebeat"
          config:
            - type: container
              paths:
                - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
              tail_files: true
              json.add_error_key: true
              json.overwrite_keys: true
              json.keys_under_root: true
              processors:
              - copy_fields:
                  fields:
                  - from: container.name
                    to: event.dataset
                  fail_on_error: false
                  ignore_missing: true
        - condition:
            contains:
              docker.container.name: "apm-server"
          config:
            - type: container
              paths:
                - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
              tail_files: true
              json.add_error_key: true
              json.overwrite_keys: true
              json.keys_under_root: true
              processors:
              - rename:
                  fields:
                   - from: "error"
                     to: "error_apm_server"
                  ignore_missing: false
                  fail_on_error: true
              - copy_fields:
                  fields:
                  - from: container.name
                    to: event.dataset
                  fail_on_error: false
                  ignore_missing: true
        - condition:
            contains:
              docker.container.image: redis
          config:
            - module: redis
              log:
                input:
                  type: container
                  paths:
                    - /var/lib/docker/containers/*/${data.docker.container.id}-json.log
        - condition:
            contains:
              docker.container.image: "postgres"
          config:
            - module: postgresql
              log:
                input:
                  type: container
                  paths:
                    - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
        - condition:
            and:
              - not:
                  contains:
                    docker.container.name: "apm-server"
              - not:
                  contains:
                    docker.container.name: "filebeat"
              - not:
                  contains:
                    docker.container.name: "heartbeat"
              - not:
                  contains:
                    docker.container.name: "kibana"
              - not:
                  contains:
                    docker.container.name: "metricbeat"
              - not:
                  contains:
                    docker.container.name: "opbeans-"
              - not:
                  contains:
                    docker.container.name: "postgres"
          config:
            - type: container
              paths:
                - "/var/lib/docker/containers/*/${data.docker.container.id}-json.log"
              tail_files: true
              processors:
              - copy_fields:
                  fields:
                  - from: container.name
                    to: event.dataset
                  fail_on_error: false
                  ignore_missing: true
```

### 2. 重新啟動 Filebeat

```
docker-compose restart filebeat
```

### 3. 查看 Log 以確認 Filebeat 運作是否正常 (Optional)

```
docker-compose logs -f filebeat
```

### 4. 進入 Kibana 查看 Containers 的 Logs。

接下來，可以進入 Kibana (http://localhost:5601) 在 Observability > Logs > Stream (http://localhost:5601/app/logs/stream) 查看是否 Log 有成功傳送到 Elasticsearch 中。

:::info
可以在搜尋框中，嘗試打入 `event.dataset: opbeans-`，**自動完成**的功能會列出目前有的 `event.dataset` 的值供選取，如果有成功將 `opbeans-node`, `opbeans-python`, `opbeans-go`...這些服務的 Logs 收集到，就可以針對這些服務進行篩選。
:::

![](https://i.imgur.com/nc3xagl.png)


## 任務三：收集 Opbeans 各服務所產生的 Metrics

### 1. 設定 `metricbeat.yml`

修改 `./docker/metricbeat/metricbeat.yml` 

在 `metricbeat.monitors` 的部份配置以下設定：

```yaml
metricbeat.modules:
  - module: golang
    metricsets: ["expvar", "heap"]
    period: 10s
    hosts: ["${APM_SERVER_PPROF_HOST:apm-server:6060}"]
    heap.path: "/debug/vars"
    expvar:
      namespace: "apm-server"
      path: "/debug/vars"
  - module: docker
    metricsets: ["container", "cpu", "diskio", "healthcheck", "info", "memory", "network"]
    hosts: ["unix:///var/run/docker.sock"]
    period: 10s
```

在 `metricbeat.autodiscover` 的部份配置以下設定：

```yaml
metricbeat.autodiscover:
  providers:
    - type: docker
      hints.enabled: true
      templates:
        - condition:
            contains:
              docker.container.image: "redis"
          config:
            - module: redis
              metricsets: ["info", "keyspace"]
              hosts: "${data.host}:6379"
        - condition:
            contains:
              docker.container.image: "postgres"
          config:
            - module: postgresql
              metricsets: ["database", "bgwriter", "activity"]
              hosts: ["postgres://${data.host}:5432?sslmode=disable"]
              password: verysecure
              username: postgres
        - condition:
            contains:
              docker.container.image: "kafka"
          config:
            - module: kafka
              metricsets: ["consumergroup", "partition"]
              period: 10s
              hosts: "${data.host}:9092"
        - condition:
            contains:
              docker.container.image: "logstash"
          config:
            - module: logstash
              metricsets: ["node", "node_stats"]
              period: 10s
              hosts: "${data.host}:9600"
```

### 2. 重新啟動 Metricbeat

```
docker-compose restart metricbeat
```

### 3. 從 Kibana 以確認 Metricbeat 運作是否正常

接下來，可以進入 Kibana 在 Observability > Infrastructure > Inventory (http://localhost:5601/app/metrics/inventory) ，切換 Show 為 `Docker Containers` 查看是否 Metricbeat 有成功傳送資料到 Elasticsearch 中。

![](https://i.imgur.com/oM42cN8.png)


## 任務四：收集 Opbeans 各服務所產生的 Traces

:::warning
這個部份由於需要改 Code，這次 Workshop 時間有限，不在這邊練習，目前執行的版本，已經都實作好 APM Agents 的部份，同時 APM Server 也透過 Elastic Agent 在運作了。
:::

除了參考 Elastic 官方 [APM 的說明文件](https://www.elastic.co/guide/en/apm/index.html)，可以配合從 [Elastic GitHub 搜尋 `opbeans-`](https://github.com/elastic?q=opbeans-&type=all&language=&sort=) ，查看目前所執行的 opbeans 各種語系專案的實作方式。

例如 `opbeans-node` 的 NodeJS 的 [`server.js`](https://github.com/elastic/opbeans-node/blob/main/server.js) 實作參考。


## 任務五：監控 Opbeans 的服務運作狀態 (Uptime)

### 設定 `heartbeat.yml`

修改 `./docker/heartbeat/heartbeat.yml` 

在 `heartbeat.monitors` 的部份配置以下設定：

```yaml
heartbeat.monitors:
  - type: http
    name: onedoggo training web
    schedule: '@every 60s'
    urls: ["https://training.onedoggo.com/"]
    check.response.status: 200
    tags: ["3rdParty"]
    fields:
      env: production
  - type: http
    name: "opbeans web"
    schedule: '@every 10s'
    urls: [
      "http://opbeans-node:3000",
      "http://opbeans-java:3000",
      "http://opbeans-python:3000",
      "http://opbeans-go:3000",
      "http://opbeans-ruby:3000"
      ]
    check.response.status: 200
    tags: ["web", "opbeans"]
    fields:
      env: production
```

另外在 `heartbeat.autodiscover` 的部份配置以下設定：

```yaml
heartbeat.autodiscover:
  providers:
    - type: docker
      templates:
        - condition:
            contains:
              docker.container.image: redis
          config:
            - type: tcp
              name: "${data.docker.container.name}"
              hosts: ["${data.host}:${data.port}"]
              schedule: "@every 1s"
              timeout: 1s
              tags: ["DB", "container"]
        - condition:
            and:
              - contains:
                  docker.container.image: opbeans
              - not:
                  contains:
                    docker.container.name: opbeans-load-generator
          config:
            - type: http
              name: "${data.docker.container.name}"
              urls: ["http://${data.host}:${data.port}"]
              schedule: "@every 5s"
              timeout: 1s
              tags: ["opbeans","container"]
```

### 重新啟動 Heartbeat

```
docker-compoes restart heartbeat
```

### 從 Kibana 以確認 Heartbeat 運作是否正常

接下來，可以進入 Kibana 在 Observability > Uptime > Monitors (http://localhost:5601/app/uptime) 查看是否 Heartbeat 的 monitors 有成功傳送到 Elasticsearch 中。

### 加強版設定

增加 `heartbeat.monitors` 的配置：
- 從 container 外部對於 Redis 的監控
- 從 container 外部存取 opbeans web 的監控

```yaml
heartbeat.monitors:
  - type: http
    name: onedoggo training web
    schedule: '@every 60s'
    urls: ["https://training.onedoggo.com/"]
    check.response.status: 200
    tags: ["3rdParty"]
    fields:
      env: production
  - type: http
    name: "opbeans web"
    schedule: '@every 10s'
    urls: [
      "http://opbeans-node:3000",
      "http://opbeans-java:3000",
      "http://opbeans-python:3000",
      "http://opbeans-go:3000",
      "http://opbeans-ruby:3000"
      ]
    check.response.status: 200
    tags: ["web", "opbeans"]
    fields:
      env: production
  # - type: http
  #   name: "opbeans web public access"
  #   schedule: '@every 10s'
  #   urls: [
  ## localhost 要換成 IP，否則 Docker Container 內部存取 localhost 會是錯誤的。
  #     "http://localhost:3000",
  #     "http://localhost:3001",
  #     "http://localhost:3002",
  #     "http://localhost:3003",
  #     "http://localhost:8000"
  #     ]
  #   check.response.status: 200
  #   tags: ["web", "opbeans"]
  #   fields:
  #     env: production
  - type: tcp
    name: redis healthcheck
    schedule: '@every 5s'
    hosts: ["redis:6379"]
    tags: ["DB"]
    fields:
      env: production
```



## 任務六：設定異常時的主動通知 - Alert

### 1. Service Level Indicator & Objective - 1

建立新的 Alert，選擇 Rule Type 為 **Uptime monitor status**，並依照需求填入設定。

![](https://i.imgur.com/7tSfu14.png)

Actions 的部份，以 Index 為例，建立新的 Index Connector：

![](https://i.imgur.com/kOkfuBW.png)


**Document to index** 的 index document 簡單範例：

```
{
    "rule_id": "{{rule.id}}",
    "rule_name": "{{rule.name}}",
    "alert_id": "{{alert.id}}",
    "context_message": "{{context.message}}"
}
```

![](https://i.imgur.com/0gEq5JH.png)


### 2. Service Level Indicator & Objective - 2

建立新的 Alert，選擇 Rule Type 為 **APM Latency threshold**，並依照需求填入設定。

依需求建立 `Web Latency SLI-2-1`

![](https://i.imgur.com/NjNxnF0.png)

依需求建立 `Web Latency SLI-2-2`

![](https://i.imgur.com/yW9mRH9.png)

**Document to index** 的 index document 使用一樣的簡單範例：

```
{
    "rule_id": "{{rule.id}}",
    "rule_name": "{{rule.name}}",
    "alert_id": "{{alert.id}}",
    "context_message": "{{context.message}}"
}
```

### 3. 建立完成後，可以在 Manage Rules 的頁面查看結果。

在 [Kibana > Alert > Manage Rules (右上角)](http://localhost:5601/app/observability/alerts/rules) 可以查看 Rules 設定結果。

![](https://i.imgur.com/qflb4f8.png)


## 使用 Elastic Observability 查找問題的技巧

### 別忘記內建的 Dashboard

- [Metricbeat Docker] Overview ECS
- [Filebeat PostgreSQL] Overview ECS
- [Metricbeat PostgreSQL] Database Overview

### 利用 Machine Learning

- Logs
    - Anomalies: 主要是針對 log entry rates (輸入率) 來進行異常的判斷。
    - Categories: 依照收集到的 Logs 進行分類，前且顯示總數量、Datasets 的來源、並且借由 Trend (趨勢) 的變化及數量來快速判斷異常的狀況。

### 


## FAQ

### 執行 `composer.py` 時 Docker build 出現 `GPG error`

docker 出現 GPG error: At least one invalid signature was encountered 相關問題及解決辦法。

> There are a few reasons why you encounter these errors:
> 
> There might be an issue with the existing cache and/or disc space. In order to fix it you need to clear the APT cache by executing: sudo apt-get clean and sudo apt-get update.
> 
> The same goes with existing docker images. Execute: docker image prune -f and docker container prune -f in order to remove unused data and free disc space.
> 
> If you don’t care about the security risks, you can try to run the apt-get command with the --allow-unauthenticated or --allow-insecure-repositories flag. According to the docs:
> 
> Ignore if packages can’t be authenticated and don’t prompt about it. This can be useful while working with local repositories, but is a huge security risk if data authenticity isn’t ensured in another way by the user itself.
> 
> Finally, on MacOS, where Docker runs inside a dedicated VM, you may need to increase the disk available to Docker from the Docker Desktop application (Settings -> Resources -> Advanced -> Disk image size).

:::danger
執行以下指令會將你的 Docker 環境清空，包含 images, dangling build caches, containers，請確認後再操作。
:::

```
docker container prune
docker image prune -a 
docker system prune
docker system df
```

### 啟動時，發生 `unhealthy` 的錯誤

```
ERROR: for opbeans-node  Container "907fc7a0c9be" is unhealthy.

ERROR: for opbeans-load-generator  Container "24e4d86c54ed" is unhealthy.
ERROR: Encountered errors while bringing up the project.
Traceback (most recent call last):
  File "/Users/joecwu/projects/joecwu/apm-integration-testing/./scripts/compose.py", line 31, in <module>
    main()
  File "/Users/joecwu/projects/joecwu/apm-integration-testing/./scripts/compose.py", line 17, in main
    setup()
  File "/Users/joecwu/projects/joecwu/apm-integration-testing/scripts/modules/cli.py", line 213, in __call__
    self.args.func()
  File "/Users/joecwu/projects/joecwu/apm-integration-testing/scripts/modules/cli.py", line 590, in start_handler
    self.build_start_handler("start")
  File "/Users/joecwu/projects/joecwu/apm-integration-testing/scripts/modules/cli.py", line 782, in build_start_handler
    self.run_docker_compose_process(docker_compose_cmd + up_params)
  File "/Users/joecwu/projects/joecwu/apm-integration-testing/scripts/modules/cli.py", line 476, in run_docker_compose_process
    subprocess.check_call(docker_compose_cmd)
  File "/Users/joecwu/.pyenv/versions/3.9.2/lib/python3.9/subprocess.py", line 373, in check_call
    raise CalledProcessError(retcode, cmd)
subprocess.CalledProcessError: Command '['docker-compose', '-f', '/Users/joecwu/projects/joecwu/apm-integration-testing/docker-compose.yml', 'up', '-d']' returned non-zero exit status 1.
```

有可能是當下某一些有相依性的 service 還沒有正常的啟動，可以先重新使用 `docker-compose` 啟動一次試試，看看是否有改善。

```
docker-compose up -d
```

若是依然有服務沒辦法正常啟動，可使用 `docker ps -a` 查看沒有正常啟動的服務是哪些，並進一步使用 `docker logs {{DockerContainerName}}` 查看錯誤訊息。

### `opbeans-dotnet` 在 Apple M1 無法啟動

使用 `docker logs localtesting_8.4.1_opbeans-dotnet` 查看，發現以下錯誤：

```
Failed to resolve full path of the current executable [/proc/self/exe]
```

:::warning
在這次 Workshop 中，若是使用 Apple M1，我們先不啟用 `opbeans-dotnet`
:::


### 如果已經啟動過，但想要清空環境，重新再來

先清除所有正在運作中的 containers，以下方式二擇一：

1. 使用 `composer.py`

```
./scripts/compose.py stop
```

2. 使用 `docker-compose`
```
docker-compose down
```

如果有需要，可以一併刪除已產生的 docker volume.

```
docker volume rm apm-integration-testing_esdata
docker volume rm apm-integration-testing_pgdata
```

### 如果要使用雲端主機，可以設定 SSH Tunnel 來存取

`~/.ssh/config` 的參考設定如下：

```
Host gcptunnel
    HostName <my.gcp.host.ip>
    IdentityFile ~/.ssh/google_compute_engine           <--- yours may differ
    User jamie                                          <--- yours probably differs
    Compression yes
    ExitOnForwardFailure no
    LocalForward 3000 127.0.0.1:3000
    LocalForward 3001 127.0.0.1:3001
    LocalForward 3002 127.0.0.1:3002
    LocalForward 3003 127.0.0.1:3003
    LocalForward 3004 127.0.0.1:80
    LocalForward 5601 127.0.0.1:5601
    LocalForward 8000 127.0.0.1:8000
    LocalForward 9200 127.0.0.1:9200
    LocalForward 9222 127.0.0.1:9222
```

以上述的例子，設定完成後，執行 `ssh gcptunnel` 即可將本機的 port 轉接到雲端主機。



## 參考資料

- 喬叔帶你上手 Elastic Stack - 探索與實踐 Observability 系列 - [使用 APM-Integratoin-Testing 建立 Elastic APM 的模擬環境](https://training.onedoggo.com/tech-sharing/uncle-joe-teach-es-elastc-observability/traces-guan-cha-ying-yong-cheng-shi-de-xiao-neng-ping-jing/shi-yong-apmintegratointesting-jian-li-elastic-apm-de-mo-ni-huan-jing)
- Elastic Demo Site: 
    - [https://demo.elastic.co](https://demo.elastic.co)
    - Observability: [https://demo.elastic.co/app/observability/overview](https://demo.elastic.co/app/observability/overview)

:::success
以上有關 `.yaml` 檔的修改，已 commit 在喬叔 GitHub 的 `2022-devopsdays-workshop` branch 之中，可以直接 `git checkout 2022-devopsdays-workshop`，或是[點此](https://github.com/joecwu/apm-integration-testing/archive/refs/heads/2022-devopsdays-workshop.zip)下載。
:::