#!/bin/bash
# ------------------------------------------
# EC2 User Data: Flask + Apache + gunicorn 自動部署
# 加入日誌輸出與錯誤停止
# ------------------------------------------

# 遇到錯誤立即停止
set -e

# 將所有 stdout/stderr 同時寫入 /var/log/user-data.log，並輸出到 console >> sudo cat /var/log/user-data.log
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "=== User Data 開始執行 ==="

#安裝套件
echo "安裝套件"
dnf -y install httpd httpd-devel firewalld python3-pip python3-devel nmap-ncat mariadb105

#啟動Apache、firewall
echo "啟動Apache、firewall"
systemctl start httpd
systemctl enable httpd
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
#下載s3檔案並安裝
echo "下載s3檔案並安裝"
aws s3 cp s3://lys-tf-app-bucket-main/${app_name}.tar.gz /tmp/${app_name}.tar.gz
tar -xzf /tmp/${app_name}.tar.gz -C /var/www
# 設定應用程式目錄和權限
APP_DIR="/var/www/${app_name}"
chown -R ec2-user:apache "$APP_DIR"
chmod -R 755 "$APP_DIR"

# 定義 VENV 路徑變數
echo "定義 虛擬環境"
VENV_DIR="$APP_DIR/venv"
GUNICORN_BIN="$VENV_DIR/bin/gunicorn"
PIP_BIN="$VENV_DIR/bin/pip"

# 以 ec2-user 身份建立虛擬環境
sudo -u ec2-user python3 -m venv "$VENV_DIR"


#安裝python套件
echo "安裝python套件"
sudo -u ec2-user "$PIP_BIN" install flask
sudo -u ec2-user "$PIP_BIN" install mysql-connector-python
sudo -u ec2-user "$PIP_BIN" install gunicorn
sudo -u ec2-user "$PIP_BIN" install python-dotenv
pip3 install mysql-connector-python
pip3 install flask
pip3 install gunicorn
pip3 install python-dotenv


# 建立 Apache 虛擬主機設定
echo "建立 Apache 虛擬主機設定..."
tee /etc/httpd/conf.d/enable_proxy.conf > /dev/null <<'EOF'
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
EOF

tee /etc/httpd/conf.d/${app_name}.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName localhost

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:5000/
    ProxyPassReverse / http://127.0.0.1:5000/
    
    ErrorLog /var/log/httpd/${app_name}-error.log
    CustomLog /var/log/httpd/${app_name}-access.log combined
</VirtualHost>
EOF

# 重新載入 Apache
echo "重啟 Apache..."
systemctl restart httpd

#設定環境變數>RDS 的連線資訊
echo "設定環境變數>RDS 的連線資訊"
export DB_HOST=${db_host}
export DB_USER=${db_user}
export DB_PASSWORD=${db_password}
export DB_DATABASE=${db_database}

printenv | grep DB_ > /var/www/${app_name}/.env
printenv | grep DB_ > /var/www/${app_name}/venv/.env
# 建立 systemd 服務檔
echo "建立 systemd 服務檔"
cat > /etc/systemd/system/flaskapp.service << EOF
[Unit]
Description=Gunicorn Flask App
After=network.target

[Service]
User=ec2-user
Group=apache
WorkingDirectory=/var/www/${app_name}
ExecStart=$GUNICORN_BIN -w 4 -b 127.0.0.1:5000 FLASK:app 
Restart=always
RestartSec=5
Environment="DB_HOST=${db_host}"
Environment="DB_USER=${db_user}"
Environment="DB_PASSWORD=${db_password}"
Environment="DB_DATABASE=${db_database}"
[Install]
WantedBy=multi-user.target
EOF

# 重新載入 systemd
systemctl daemon-reload

# 啟用並啟動服務
systemctl enable flaskapp
systemctl start flaskapp

# 確定有接上RDS
cd /var/www/${app_name}
python3 FLASK.py
echo "=== User Data 執行完成 ==="