#!/bin/bash

# Change this!
IP="192.168.0.1" # ELK stack IP
USER="elastic" # ELK user
PASSWORD="chiapet1" # ELK password
VERSION="8.6.2" # version
REPO="https://artifacts.elastic.co/downloads/beats" # software repo root
DOWNLOAD_PATH="/root" # where to download and run everything from

# Download and extract files
cd $DOWNLOAD_PATH
for i in {auditbeat,filebeat}; do
URL="$REPO/$i/$i-$VERSION-linux-x86_64.tar.gz"
curl -L -O $URL || wget $URL
tar -xvzf "$i-$VERSION-linux-x86_64.tar.gz"
done
# Stop auditd
service auditd stop
# Edit Auditbeat configuration
cd "auditbeat-$VERSION-linux-x86_64"
sed -i 's/^  - \/etc$/  - \/etc\n  - \/lib\n  - \/usr\/lib/' auditbeat.yml
sed -i "s/^setup.kibana:$/setup.kibana:\n  host: \"$IP:5601\"/" auditbeat.yml
sed -i "s/^  hosts: \[\"localhost:9200\"\]$/  hosts: [\"$IP:9200\"]\n  username: \"$USER\"\n  password: \"$PASSWORD\"/" auditbeat.yml
# Add Auditbeat sample rules
cp audit.rules.d/sample-rules.conf.disabled audit.rules.d/sample-rules.conf
# Start Auditbeat
./auditbeat setup # Comment out after first machine
cat > /usr/lib/systemd/system/auditbeat.service << EOF
[Unit]
Description=Auditbeat
After=network.target

[Service]
ExecStart=$DOWNLOAD_PATH/auditbeat-$VERSION-linux-x86_64/auditbeat
ExecReload=/usr/bin/kill -s SIGHUP \$MAINPID
Restart=on-abort
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
systemctl enable auditbeat --now
# Edit Filebeat configuration
cd "../filebeat-$VERSION-linux-x86_64"
sed -i "s/^setup.kibana:$/setup.kibana:\n  host: \"$IP:5601\"/" filebeat.yml
sed -i "s/^  hosts: \[\"localhost:9200\"\]$/  hosts: [\"$IP:9200\"]\n  username: \"$USER\"\n  password: \"$PASSWORD\"/" filebeat.yml
# Add Filebeat sample rules
cp modules.d/system.yml.disabled modules.d/system.yml
sed -i 's/false/true/g' modules.d/system.yml
# Start Filebeat
./filebeat setup # Comment out after first machine
cat > /usr/lib/systemd/system/filebeat.service << EOF
[Unit]
Description=Filebeat
After=network.target

[Service]
ExecStart=$DOWNLOAD_PATH/filebeat-$VERSION-linux-x86_64/filebeat
ExecReload=/usr/bin/kill -s SIGHUP \$MAINPID
Restart=on-abort
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
systemctl enable filebeat --now
cd ..
exit 0
