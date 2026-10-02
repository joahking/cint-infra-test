#!/bin/bash

set -e

dnf update -y
dnf install -y nginx

cat > /etc/application.env <<'EOF'
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_SECRET_ARN=${db_secret_arn}
EOF

cat > /usr/share/nginx/html/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Application</title>
</head>
<body>
    <h1>Application is running</h1>
</body>
</html>
HTML

systemctl enable nginx
systemctl start nginx