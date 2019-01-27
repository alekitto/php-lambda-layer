#!/bin/bash

set -eux

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib
PHPIZE_DEPS="
    autoconf
    file
    gcc-c++
    gcc
    glibc-devel
    make
    pkgconfig
    re2c
"

yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-2.noarch.rpm > mysql80.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/j/jsoncpp-0.10.5-2.el7.x86_64.rpm
yum install -y http://mirror.ghettoforge.org/distributions/gf/el/7/plus/x86_64/cmake-3.3.2-1.gf.el7.x86_64.rpm

yum makecache
yum install -y \
        $PHPIZE_DEPS \
		ca-certificates \
		curl \
		dirmngr \
		gnupg \
		tar \
		wget \
		xz \
		zip

PHP_INI_DIR=/opt/etc/php
PHP_EXTRA_CONFIGURE_ARGS="--enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --disable-cgi"
PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
PHP_CPPFLAGS="$PHP_CFLAGS"
PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

GPG_KEYS="CBAF69F173A0FEA4B537F470D66C9593118BCCB6 F38252826ACD957EF380D39F2F7956BC5DA04B5D"

PHP_VERSION="7.3.1"
PHP_URL="https://secure.php.net/get/php-7.3.1.tar.xz/from/this/mirror"
PHP_ASC_URL="https://secure.php.net/get/php-7.3.1.tar.xz.asc/from/this/mirror"
PHP_SHA256="cfe93e40be0350cd53c4a579f52fe5d8faf9c6db047f650a4566a2276bf33362"

mkdir -p /usr/src/php
cd /usr/src

wget -O php.tar.xz "$PHP_URL"
echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -

wget -O php.tar.xz.asc "$PHP_ASC_URL"
export GNUPGHOME="$(mktemp -d)"
for key in $GPG_KEYS; do
    ( gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" \
      || gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" \
      || gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" \
      || gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key" \
      || gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" \
      || gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" )
done

gpg --batch --verify php.tar.xz.asc php.tar.xz
rm -rf "$GNUPGHOME"

yum install -y \
    libcurl-devel \
    libedit-devel \
    sqlite \
    openssl-devel \
    libxml2-devel \
    libpng-devel \
    libjpeg-devel \
    libgmp-devel \
    libicu-devel \
    mysql-community-libs \
    postgresql-devel \
    zlib-devel \
    cmake

wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.17.tar.gz -O libsodium.tar.gz
mkdir -p /src/libsodium && tar -xf libsodium.tar.gz -C /src/libsodium --strip-components=1
rm libsodium.tar.gz
cd /src/libsodium

./configure --prefix=/usr
make -j4 && make check
make install

cd /usr/src

curl -sSL https://github.com/P-H-C/phc-winner-argon2/archive/20171227.tar.gz > libargon2.tar.gz
mkdir -p /src/libargon2 && tar -xf libargon2.tar.gz -C /src/libargon2 --strip-components=1
rm libargon2.tar.gz
cd /src/libargon2

make -j4 && make test
make install

cd /usr/src

curl -sSL https://libzip.org/download/libzip-1.5.1.tar.gz > libzip.tar.gz
mkdir -p /src/libzip && tar -xf libzip.tar.gz -C /src/libzip --strip-components=1
rm libzip.tar.gz
cd /src/libzip

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j4
make install

cd /usr/src

export \
    CFLAGS="$PHP_CFLAGS" \
    CPPFLAGS="$PHP_CPPFLAGS" \
    LDFLAGS="$PHP_LDFLAGS"

tar -Jxf /usr/src/php.tar.xz -C /usr/src/php --strip-components=1
cd /usr/src/php

mkdir -p /opt

./configure \
        --prefix=/opt \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--enable-option-checking=fatal \
		--with-mhash \
		--enable-ftp \
		--enable-mbstring \
		--enable-mysqlnd \
		--with-password-argon2 \
		--with-sodium=static \
		--with-curl \
		--with-libedit \
		--with-openssl \
		--with-zlib \
		--with-gd \
		--with-gmp \
		--enable-exif \
		--enable-bcmath \
		--enable-sockets \
		--with-mysqli=mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--with-pgsql \
		--with-pdo-pgsql \
		--enable-opcache \
		--enable-libxml \
		--enable-soap \
		--enable-zip \
		--with-xsl \
		${PHP_EXTRA_CONFIGURE_ARGS:-}

make -j "$(nproc)"
make install

find /opt/bin /opt/sbin -type f -executable -exec strip --strip-all '{}' + || true
make clean

cd /src

wget https://github.com/mongodb/mongo-php-driver/releases/download/1.5.3/mongodb-1.5.3.tgz -O mongodb.tgz
mkdir -p /src/mongodb && tar -xf mongodb.tgz -C /src/mongodb --strip-components=1
rm mongodb.tgz
cd /src/mongodb

/opt/bin/phpize
./configure --with-php-config=/opt/bin/php-config
make -j4
make install

cd /src

wget https://github.com/igbinary/igbinary/releases/download/2.0.8/igbinary-2.0.8.tgz -O igbinary.tgz
mkdir -p /src/igbinary && tar -xf igbinary.tgz -C /src/igbinary --strip-components=1
rm igbinary.tgz
cd /src/igbinary

/opt/bin/phpize
./configure CFLAGS="-O2 -g" --enable-igbinary --with-php-config=/opt/bin/php-config
make -j4
make install

cd /src

wget https://github.com/phpredis/phpredis/archive/4.2.0.tar.gz -O phpredis.tar.gz
mkdir -p /src/phpredis && tar -xf phpredis.tar.gz -C /src/phpredis --strip-components=1
rm phpredis.tar.gz
cd /src/phpredis

/opt/bin/phpize
./configure CFLAGS="-O2 -g" --enable-redis-igbinary --with-php-config=/opt/bin/php-config
make -j4
make install

cd /src

wget https://pecl.php.net/get/imagick -O imagick.tgz
mkdir -p /src/imagick && tar -xf imagick.tgz -C /src/imagick --strip-components=1
rm imagick.tgz
cd /src/imagick

/opt/bin/phpize
./configure --with-php-config=/opt/bin/php-config
make -j4
make install

cd /
rm -rf /usr/src
rm -rf /src
yum clean all

/opt/bin/php --version
/opt/bin/php -m

cd /opt

mkdir -p /opt/etc/php/conf.d
echo "extension=mongodb.so" > /opt/etc/php/conf.d/mongodb.ini
echo "extension=igbinary.so" > /opt/etc/php/conf.d/igbinary.ini
echo "extension=redis.so" > /opt/etc/php/conf.d/redis.ini
echo "extension=imagick.so" > /opt/etc/php/conf.d/imagick.ini

/opt/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
/opt/bin/php -r "if (hash_file('sha384', 'composer-setup.php') === '93b54496392c062774670ac18b134c3b3a95e5a5e5c8f1a9f115f203b75bf9a129d5daa8ba6a13e2cc8a1da0806388a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
/opt/bin/php composer-setup.php --install-dir=/usr/bin --filename=composer
/opt/bin/php -r "unlink('composer-setup.php');"

cp /var/layer/composer.* .
cp /var/layer/bootstrap .
cp /var/layer/php.ini .

sed -i "s/;request_terminate_timeout = 0/request_terminate_timeout = 5/g" /opt/etc/php-fpm.d/www.conf.default
sed -i "s/;listen.allowed_clients = 127.0.0.1/listen.allowed_clients = 127.0.0.1/g" /opt/etc/php-fpm.d/www.conf.default
sed -i "s/user = www-data/;user = www-data/g" /opt/etc/php-fpm.d/www.conf.default
sed -i "s/group = www-data/;group = www-data/g" /opt/etc/php-fpm.d/www.conf.default
sed -i "s/;error_log = log\\/php-fpm.log/error_log = \\/dev\\/stderr/g" /opt/etc/php-fpm.conf.default

echo "php_admin_value[error_log] = /dev/stderr" >> /opt/etc/php-fpm.d/www.conf.default
echo "php_admin_flag[log_errors] = on" >> /opt/etc/php-fpm.d/www.conf.default

/opt/bin/php /usr/bin/composer install

mkdir -p lib
for lib in libncurses.so.5 libtinfo.so.5 libpcre.so.0; do
  cp "/lib64/${lib}" lib/
done

for lib in libargon2.so.1 libsodium.so.23; do
  cp "/usr/lib/${lib}" lib/
done

for lib in libedit.so.0 libzip.so.5 libpq.so.5; do
  cp "/usr/lib64/${lib}" lib/
done

cp /opt/etc/php-fpm.conf.default /opt/etc/php-fpm.conf
cp /opt/etc/php-fpm.d/www.conf.default /opt/etc/php-fpm.d/www.conf
zip -r /var/layer/php73.zip .
