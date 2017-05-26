#!/bin/bash
mkdir -p /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/mirror.conf <<-'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --registry-mirror=https://794gworn.mirror.aliyuncs.com
EOF
systemctl daemon-reload
systemctl restart docker
