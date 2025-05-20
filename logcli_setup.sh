curl -fLO https://github.com/grafana/loki/releases/download/v2.9.4/logcli-linux-amd64.zip
unzip logcli-linux-amd64.zip
sudo chmod +x logcli-linux-amd64
sudo mv logcli-linux-amd64 /usr/local/bin/logcli
sudo rm logcli-linux-amd64.zip