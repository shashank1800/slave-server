# Setting Up a Docker Container with MySQL as a Slave Server

This guide provides detailed instructions for setting up a Docker container with MySQL configured as a slave server. The container will connect to a master MySQL database running on your local machine and include a dummy Nginx server to keep the container running.

## Prerequisites

**Install Docker** 

Follow the instructions [here](https://docs.docker.com/engine/install/ubuntu/) to install Docker on your local machine.


## Master Configuration

**Create Mysql User `replica_write`**

Both master and slave servers should have the same user and password. Run the following commands on the master:

```
CREATE USER 'replica_write'@'%' IDENTIFIED BY 'Welcome@123';
GRANT REPLICATION SLAVE ON *.* TO 'replica_write'@'%';
FLUSH PRIVILEGES;
```

Both master and slave should have same user and password make sure to create this first in master.
For slave replica_write user will get added while running docker container.
Also grant permission for all database to the user.


**Master mysql config file changes**

Ensure your master MySQL server is configured with the following settings in `/etc/mysql/mysql.conf.d/mysqld.cnf`:

```shell
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

```ini
[mysqld]
server-id=1
port=3306
log_bin=/var/log/mysql/mysql-bin.log
bind-address=0.0.0.0
binlog_do_db=database_name
```

**Check master binlog and position**

Login to master server db check binlog and position by entering below command
```
mysql> SHOW MASTER STATUS\G;
*************************** 1. row ***************************
             File: mysql-bin.001828
         Position: 3072
     Binlog_Do_DB: database_name
 Binlog_Ignore_DB: 
Executed_Gtid_Set: 
1 row in set (0.00 sec)
```

**Create master db dump**

Run the following command to create the database dump:
```shell
mysqldump --single-transaction=TRUE -u replica_write -p database_name > db_dump.sql
```

Place the latest database dump file in `slave-server/db_dump.sql`.


## Preparing the Slave Server


## Build and Run the Docker Container

### 1. Build the Docker Image

Run the following commands in the directory containing the `Dockerfile`, `my.cnf`, and `entrypoint.sh`:

```bash
docker build -t mysql-slave .
```

```
[+] Building 4.3s (11/11) FINISHED                                                                                                                                                                          docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                                        0.0s
 => => transferring dockerfile: 679B                                                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/ubuntu:22.04                                                                                                                                                             3.6s
 => [internal] load .dockerignore                                                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                                                             0.0s
 => [1/6] FROM docker.io/library/ubuntu:22.04@sha256:0e5e4a57c2499249aafc3b40fcd541e9a456aab7296681a3994d631587203f97                                                                                                       0.0s
 => [internal] load build context                                                                                                                                                                                           0.0s
 => => transferring context: 902B                                                                                                                                                                                           0.0s
 => CACHED [2/6] RUN apt-get update && apt-get install -y     mysql-server     nginx     curl     nano     net-tools     && apt-get clean                                                                                   0.0s
 => CACHED [3/6] COPY my.cnf /my.cnf                                                                                                                                                                                        0.0s
 => [4/6] COPY db_dump.sql /db_dump.sql                                                                                                                                                                                     0.0s
 => [5/6] COPY entrypoint.sh /entrypoint.sh                                                                                                                                                                                 0.1s
 => [6/6] RUN chmod +x /entrypoint.sh                                                                                                                                                                                       0.3s
 => exporting to image                                                                                                                                                                                                      0.1s
 => => exporting layers                                                                                                                                                                                                     0.1s
 => => writing image sha256:957efc91c7e61fd43d459d9ad6aa2d6cde5d5d89d18efb3fb6961bcd7941d62d                                                                                                                                0.0s
 => => naming to docker.io/library/mysql-slave                                                                                                                                                                              0.0s
 
```

> **Note:** Ensure the database dump file (`db_dump.sql`) is placed correctly to avoid errors.

### 2. Run the Docker Container

Start the container, mapping ports for MySQL (3306) and Nginx (80):

```bash
docker run -d --name mysql-slave -p 3307:3306 -p 8085:80 mysql-slave
```

### 3. Log into the Docker Container

Access the container’s terminal:

```bash
docker exec -it mysql-slave bash
```

## Accessing Databases

### Access Master Database from Slave terminal

Test connectivity from the container to the master server:

```bash
mysql -h <master_ip> -u replica_write -p
```

> **Note:** You can check ip by executing `ip a` command in terminal.

### Access Slave Database from Master terminal

Log in to the slave database:

```bash
docker exec -it mysql-slave mysql -u replica_write -p
```

Password: `Welcome@123`

## Configuring Replication

### Check Master and Slave status

Run the following command on the master database to get the binlog file and position:

```sql
SHOW MASTER STATUS\G
```

Run the following command on the slave database to get the slave status:

```sql
SHOW SLAVE STATUS\G
```

## Logging into the Database

Log in with the credentials:

```bash
mysql -u replica_write -pWelcome@123
```


