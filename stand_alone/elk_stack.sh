#!/bin/bash
sudo su
apt-get update
apt-get upgrade -y
apt-get install openjdk-11-jdk wget apt-transport-https curl gnupg2 -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch --no-check-certificate | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt-get update
apt-get install elasticsearch -y
cd /etc/elasticsearch/
rm -rf elasticsearch.yml
cat <<EOF > elasticsearch.yml
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
EOF
systemctl start elasticsearch
systemctl enable elasticsearch
systemctl restart elasticsearch

apt-get install logstash -y
cat <<EOF > input1.conf
input {
beats {
port => 5044
}
}
EOF
mv input1.conf /etc/logstash/conf.d/
cat <<EOF > elasticsearch-output.conf
output {
elasticsearch {
hosts => ["0.0.0.0:9200"]
manage_template => false
index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
}
}
EOF
mv elasticsearch-output.conf /etc/logstash/conf.d/
systemctl start logstash
systemctl enable logstash
apt-get install kibana
cd /etc/kibana/
rm -rf kibana.yml
cat <<EOF > kibana.yml
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://0.0.0.0:9200"]
EOF
cd ..
cd ..
systemctl start kibana
systemctl enable kibana
systemctl restart kibana
apt-get install filebeat -y
systemctl start filebeat
systemctl enable filebeat
systemctl restart filebeat

filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["0.0.0.0:9200"]'
cd ~

