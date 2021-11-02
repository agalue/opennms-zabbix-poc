#cloud-config

# This is a Terraform template_file. It cannot be used directly as a cloud-init script.
# https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file

package_upgrade: false
timezone: America/New_York

write_files:
- owner: root:root
  path: /opt/opennms/etc/org.opennms.features.datachoices.cfg
  content: |
    enabled=false
    acknowledged-by=admin
    acknowledged-at=Mon Jan 01 00\:00\:00 EDT 2021

- owner: root:root
  path: /opt/opennms/etc/opennms.properties.d/web.properties
  content: |
    org.opennms.web.defaultGraphPeriod=last_2_hour
    org.opennms.security.disableLoginSuccessEvent=true
    org.opennms.netmgt.jetty.host = 127.0.0.1
    opennms.web.base-url = https://%x%c/

- owner: root:root
  path: /opt/opennms/etc/opennms.properties.d/rrd.properties
  content: |
    org.opennms.rrd.storeByGroup=true
    org.opennms.rrd.storeByForeignSource=true

- owner: root:root
  path: /opt/opennms/etc/opennms.properties.d/cortex.properties
  content: |
    org.opennms.timeseries.strategy=integration
    org.opennms.timeseries.tin.metatags.tag.node=$${node:label}
    org.opennms.timeseries.tin.metatags.tag.location=$${node:location}
    org.opennms.timeseries.tin.metatags.tag.geohash=$${node:geohash}
    org.opennms.timeseries.tin.metatags.tag.ifDescr=$${interface:if-description}
    org.opennms.timeseries.tin.metatags.tag.label=$${resource:label}

- owner: root:root
  path: /opt/opennms/etc/org.opennms.plugins.tss.cortex.cfg
  content: |
    writeUrl=http://localhost:9009/api/prom/push
    readUrl=http://localhost:9009/prometheus/api/v1
    maxConcurrentHttpConnections=100
    writeTimeoutInMs=1000
    readTimeoutInMs=1000
    metricCacheSize=1000
    bulkheadMaxWaitDurationInMs=9223372036854775807

- owner: root:root
  path: /opt/opennms/etc/opennms.properties.d/kafka.properties
  content: |
    # Disable internal ActiveMQ
    org.opennms.activemq.broker.disable=true
    # Sink
    org.opennms.core.ipc.sink.strategy=kafka
    org.opennms.core.ipc.sink.kafka.bootstrap.servers=${eh_bootstrap}
    org.opennms.core.ipc.sink.kafka.acks=1
    org.opennms.core.ipc.sink.kafka.security.protocol=SASL_SSL
    org.opennms.core.ipc.sink.kafka.sasl.mechanism=PLAIN
    org.opennms.core.ipc.sink.kafka.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="${eh_connstr}";
    # RPC
    org.opennms.core.ipc.rpc.strategy=kafka
    org.opennms.core.ipc.rpc.kafka.bootstrap.servers=${eh_bootstrap}
    org.opennms.core.ipc.rpc.kafka.ttl=30000
    org.opennms.core.ipc.rpc.kafka.auto.offset.reset=latest
    org.opennms.core.ipc.rpc.kafka.security.protocol=SASL_SSL
    org.opennms.core.ipc.rpc.kafka.sasl.mechanism=PLAIN
    org.opennms.core.ipc.rpc.kafka.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="${eh_connstr}";

- owner: root:root
  path: /opt/opennms/etc/opennms.conf
  content: |
    START_TIMEOUT=0
    JAVA_HEAP_SIZE=2048
    MAXIMUM_FILE_DESCRIPTORS=204800
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -Djava.net.preferIPv4Stack=true"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -Xlog:gc:/opt/opennms/logs/gc.log"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:+UseStringDeduplication"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:+UseG1GC"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:G1RSetUpdatingPauseTimePercent=5"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:MaxGCPauseMillis=500"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:InitiatingHeapOccupancyPercent=70"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:ParallelGCThreads=1"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:ConcGCThreads=1"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:+ParallelRefProcEnabled"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:+AlwaysPreTouch"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:+UseTLAB"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:+ResizeTLAB"
    ADDITIONAL_MANAGER_OPTIONS="$ADDITIONAL_MANAGER_OPTIONS -XX:-UseBiasedLocking"

- owner: root:root
  path: /opt/opennms/deploy/features.xml
  content: |
    <?xml version="1.0" encoding="UTF-8"?>
    <features name="opennms-time-series" xmlns="http://karaf.apache.org/xmlns/features/v1.4.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://karaf.apache.org/xmlns/features/v1.4.0 http://karaf.apache.org/xmlns/features/v1.4.0">
      <repository>mvn:org.opennms.plugins.timeseries/cortex-karaf-features/1.0.0-SNAPSHOT/xml</repository>
      <repository>mvn:org.opennms.plugins.zabbix/karaf-features/1.0.0-SNAPSHOT/xml</repository>
      <feature name="autostart-zabbix" description="Zabbix Auto-Start" version="1.0.0" start-level="200" install="auto">
        <feature>opennms-plugins-cortex-tss</feature>
        <feature>opennms-plugins-zabbix</feature>
      </feature>
    </features>

- owner: root:root
  permissions: '0755'
  path: /opt/opennms/bin/setup-plugins.sh
  content: |
    #!/bin/bash

    cd /opt/opennms
    git clone https://github.com/OpenNMS/opennms-cortex-tss-plugin.git cortex
    cd cortex
    mvn install -DskipTests
    cd ..

    git clone https://github.com/OpenNMS/opennms-zabbix-plugin.git zabbix
    cd zabbix
    mvn install -DskipTests
    cd ..

- owner: root:root
  permissions: '0755'
  path: /opt/opennms/bin/setup-opennms.sh
  content: |
    #!/bin/bash

    echo "Configuring Nginx for LetsEncrypt..."
    mkdir -p /var/www/${onms_fqdn}/.well-known
    chown nginx:nginx /var/www
    setsebool -P httpd_can_network_connect 1

    echo "Installing and configuring Grafana"
    dnf install -y https://dl.grafana.com/oss/release/grafana-8.2.2-1.x86_64.rpm
    sed -i -r "s|^;domain =.*|domain = ${onms_fqdn}|" /etc/grafana/grafana.ini
    sed -i -r "s|^;root_url =.*|root_url = %(protocol)s://%(domain)s:%(http_port)s/grafana/|" /etc/grafana/grafana.ini

    echo "Installing and configuring Cortex"
    dnf install -y https://github.com/cortexproject/cortex/releases/download/v1.10.0/cortex-1.10.0_amd64.rpm
    
    echo "Installing OpenNMS and Helm"
    dnf install -y https://yum.opennms.org/repofiles/opennms-repo-stable-rhel8.noarch.rpm
    dnf install -y jicmp jicmp6 jrrd2
    curl -1sLf 'https://packages.opennms.com/public/develop/setup.rpm.sh' | sudo -E bash
    dnf install -y opennms-core opennms-webapp-jetty opennms-webapp-hawtio opennms-helm

    echo "OpenNMS: Compiling Plugins"
    runuser -u opennms -- /opt/opennms/bin/setup-plugins.sh

    echo "OpenNMS: Configuring PostgreSQL"
    if [ "${pg_local}" == "true" ]; then
      dnf install -y postgresql-server
      /usr/bin/postgresql-setup --initdb --unit postgresql
      sed -r -i "/^(local|host)/s/(peer|ident)/trust/g" /var/lib/pgsql/data/pg_hba.conf
      systemctl --now enable postgresql
    else
      sed -r -i 's/localhost/${pg_ipaddr}/' /opt/opennms/etc/opennms-datasources.xml
      sed -r -i 's/user-name="postgres"/user-name="${pg_user}"/' /opt/opennms/etc/opennms-datasources.xml
      sed -r -i 's/password=""/password="${pg_passwd}"/' /opt/opennms/etc/opennms-datasources.xml
    fi

    echo "OpenNMS: Configuring JMX"
    num_cores=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
    half_cores=$(expr $num_cores / 2)
    total_mem_in_mb=$(free -m | awk '/:/ {print $2;exit}')
    mem_in_mb=$(expr $total_mem_in_mb / 2)
    if [[ "$mem_in_mb" -gt "30720" ]]; then
      mem_in_mb="30720"
    fi
    sed -r -i "/JAVA_HEAP_SIZE/s/=.*/=$mem_in_mb/" /opt/opennms/etc/opennms.conf
    sed -r -i "/GCThreads=/s/1/$half_cores/" /opt/opennms/etc/opennms.conf

    echo "OpenNMS: Configuring Logs"
    sed -r -i 's/value="DEBUG"/value="WARN"/' /opt/opennms/etc/log4j2.xml

    echo "OpenNMS: Initializing Database"
    RUNAS=opennms /opt/opennms/bin/fix-permissions
    runuser -u opennms -- /opt/opennms/bin/runjava -s
    runuser -u opennms -- /opt/opennms/bin/install -dis

    echo "Starting services"
    systemctl --now enable nginx
    systemctl --now enable cortex
    systemctl --now enable grafana-server
    systemctl --now enable opennms

    echo "Creating Certificate for Nginx via LetsEncrypt..."
    dnf install -y certbot python3-certbot-nginx
    certbot --nginx -d ${onms_fqdn} --non-interactive --agree-tos -m ${email}

- owner: root:root
  permissions: '0400'
  path: /etc/snmp/snmpd.conf
  content: |
    rocommunity public default
    syslocation Azure - ${location}
    syscontact ${user}
    dontLogTCPWrappersConnects yes
    disk /

- owner: root:root
  path: /etc/nginx/default.d/opennms.conf
  content: |
    server_name ${onms_fqdn};
    # maintain the .well-known directory alias for LetsEncrypt renewals
    location /.well-known {
      alias /var/www/${onms_fqdn}/.well-known;
    }
    location /hawtio/ {
      proxy_pass http://localhost:8980/hawtio/;
    }
    location /grafana/ {
      proxy_pass http://localhost:3000/;
    }
    location /opennms/ {
      proxy_set_header    Host $host;
      proxy_set_header    X-Real-IP $remote_addr;
      proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header    X-Forwarded-Proto $scheme;
      proxy_set_header    Upgrade $http_upgrade;
      proxy_set_header    Connection "Upgrade";
      proxy_pass          http://localhost:8980/opennms/;
      proxy_redirect      default;
      proxy_read_timeout  90;
    }

packages:
- nginx
- net-snmp
- net-snmp-utils
- epel-release
- git
- maven
- java-11-openjdk-devel

runcmd:
- dnf install -y haveged jq
- systemctl --now enable haveged
- systemctl --now enable snmpd
- /opt/opennms/bin/setup-opennms.sh
