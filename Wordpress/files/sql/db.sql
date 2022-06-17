SET GLOBAL query_cache_size = 1000000;
CREATE USER 'mysql_username'@'%' IDENTIFIED BY 'p@sswrD_4_mysql_instance';
CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON wordpress.* TO 'mysql_username'@'%';
GRANT SELECT ON mysql.* TO 'mysql_username'@'%';

USE wordpress;