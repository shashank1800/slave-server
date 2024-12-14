# Base image
FROM ubuntu:22.04

# Update the system and install required packages
RUN apt-get update && apt-get install -y \
    mysql-server \
    nginx \
    curl \
    nano \
    net-tools \
    && apt-get clean

# Set environment variables for MySQL
ENV MYSQL_ROOT_PASSWORD=Welcome@123
ENV DATABASE_NAME=db
ENV MASTER_LOG_FILE=mysql-bin.001828
ENV MASTER_LOG_POS=2220

# Expose ports for MySQL and Nginx
EXPOSE 3306 80

# Copy MySQL configuration files
COPY my.cnf /my.cnf

# Copy the master SQL dump (to initialize the slave)
COPY db_dump.sql /db_dump.sql

# Add entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default command to run Nginx in the background
CMD ["/entrypoint.sh"]

