#!/bin/bash

# Start MySQL service
service mysql start

# Overwrite the MySQL configuration file
cp my.cnf /etc/mysql/mysql.conf.d/mysqld.cnf

# Restart MySQL to apply new configuration
service mysql restart


# Set up MySQL root user to be accessible from any host
mysql --user=root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Welcome@123';
CREATE USER 'root'@'%' IDENTIFIED BY 'Welcome@123';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Add 'replica_write' user with all privileges
mysql --user=root --password=Welcome@123 <<EOF
CREATE USER 'replica_write'@'%' IDENTIFIED BY 'Welcome@123';
GRANT ALL PRIVILEGES ON *.* TO 'replica_write'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Create database in slave server
mysql --user=root --password=Welcome@123 <<EOF
CREATE DATABASE ${DATABASE_NAME};
EOF

# Check if the master dump has already been imported else dump.
if [ ! -f /var/lib/mysql/slave_initialized.flag ]; then
    echo "Initializing slave database with master dump..."
    mysql -uroot -pWelcome@123 ${DATABASE_NAME} < db_dump.sql
    touch /var/lib/mysql/slave_initialized.flag
fi

# Restart MySQL to ensure new configuration is loaded
service mysql restart


# Configure slave replication
mysql --user=root --password=${DATABASE_NAME} <<EOF
STOP SLAVE;
STOP REPLICA IO_THREAD FOR CHANNEL '';
CHANGE MASTER TO
    MASTER_HOST='host.docker.internal',
    MASTER_USER='replica_write',
    MASTER_PASSWORD='Welcome@123',
    MASTER_LOG_FILE='${MASTER_LOG_FILE}',
    MASTER_LOG_POS=${MASTER_LOG_POS};
START REPLICA IO_THREAD FOR CHANNEL '';
START SLAVE;
EOF

# Start Nginx in the background
service nginx start

# Keep the container running
tail -f /dev/null

