#cloud-config
packages:
  - docker.io
runcmd:
  - sudo docker run --name wordpress -p 80:80 -e WORDPRESS_DB_HOST="${WORDPRESS_DB_HOST}" -e WORDPRESS_DB_USER="${WORDPRESS_DB_USER}" -e WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD}" -e WORDPRESS_DB_NAME="${WORDPRESS_DB_NAME}" -e WORDPRESS_CONFIG_EXTRA="define('WP_HOME','${WP_HOME}');define('WP_SITEURL','${WP_SITEURL}');" -d wordpress:latest
  - sudo echo "test"