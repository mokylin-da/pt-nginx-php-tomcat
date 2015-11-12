#环境的基础镜像  镜像名字  docker.36b.me/nginx-php-tomcat:latest
FROM       centos:centos7.1.1503
MAINTAINER zengweigang <zengweigang@gmail.com>

ENV TZ "Asia/Shanghai"
ENV TERM xterm

ADD aliyun-epel.repo /etc/yum.repos.d/epel.repo

RUN yum install -y curl wget tar bzip2 unzip vim-enhanced passwd sudo yum-utils hostname net-tools rsync man && \
    yum install -y gcc gcc-c++ git make automake cmake patch logrotate python-devel libpng-devel libjpeg-devel && \
    yum install -y --enablerepo=epel pwgen python-pip && \
    yum clean all

RUN pip install supervisor
ADD supervisord.conf /etc/supervisord.conf

RUN mkdir -p /etc/supervisor.conf.d && \
    mkdir -p /var/log/supervisor


# Set environment variable
ENV	APP_DIR /app

RUN	yum -y install nginx php-cli php-mysql php-pear php-ldap php-mbstring php-soap php-dom php-gd php-xmlrpc php-fpm php-mcrypt java-1.8.0-openjdk-devel.x86_64 && \ 
	yum clean all

ADD nginx_nginx.conf /etc/nginx/nginx.conf
ADD	nginx_default.conf /etc/nginx/conf.d/default.conf

ADD	php_www.conf /etc/php-fpm.d/www.conf
RUN	sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php.ini

RUN	mkdir -p /app


ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME



ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.28
ENV TOMCAT_TGZ_URL https://raw.githubusercontent.com/chentmin/dist/master/tomcat/apache-tomcat-8.0.28.tar.gz

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz*
RUN rm -Rf /usr/local/tomcat/webapps/* && mkdir -p /usr/local/tomcat/internal /usr/local/tomcat/external&& mkdir -p /usr/local/tomcat/internal /usr/local/tomcat/external
ADD server.xml /usr/local/tomcat/conf/server.xml
ADD context.xml /usr/local/tomcat/conf/context.xml
ADD	supervisor_nginx.conf /etc/supervisor.conf.d/nginx.conf
ADD	supervisor_php-fpm.conf /etc/supervisor.conf.d/php-fpm.conf
ADD	supervisor_tomcat.conf /etc/supervisor.conf.d/tomcat.conf
EXPOSE 8080 9999
ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]