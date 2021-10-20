FROM    debian:buster

LABEL   maintainer="ysji@islab.snu.ac.kr"

RUN     apt-get update && apt-get install -y \
        nginx curl\
        mariadb-server \
        php-mysql \
        php-mbstring \
        openssl \
        vim \
        wget \
        php7.3-fpm

COPY    ./srcs/run.sh ./
COPY    ./srcs/default ./tmp
COPY    ./srcs/wp-config.php ./tmp
COPY    ./srcs/config.inc.php ./tmp
        

EXPOSE  80 443

CMD     bash run.sh
