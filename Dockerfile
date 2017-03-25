FROM jsurf/rpi-raspbian:latest

MAINTAINER jsurf

RUN [ "cross-build-start" ]

# Install nginx, supervisor and backuppc
RUN apt-get update \
    && apt-get install -y supervisor debconf-utils msmtp msmtp-mta nginx libfcgi-perl openssh-client \
    && echo "postfix postfix/main_mailer_type select Local only" | debconf-set-selections \
    && echo "backuppc backuppc/configuration-note note" | debconf-set-selections \
    && echo "backuppc backuppc/restart-webserver boolean true" | debconf-set-selections \
    && echo "backuppc backuppc/reconfigure-webserver multiselect nginx" | debconf-set-selections \
    && apt-get install -y backuppc libfile-rsyncp-perl libio-dirent-perl \
	&& rm -rf /var/lib/apt/lists/* 

COPY nginx /etc/nginx
COPY fastcgi-wrapper /usr/local/bin/fastcgi-wrapper

# Nginx config
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
    && ln -s ../sites-available/backuppc /etc/nginx/sites-enabled/backuppc \
    && htpasswd -b /etc/backuppc/htpasswd backuppc password 

COPY supervisord.conf /etc/supervisord.conf
COPY msmtprc /etc/backuppc/.msmtprc.dist
COPY run.sh /run.sh
COPY ssh-config /etc/backuppc-ssh-config
	
# Backuppc config
RUN sed -i 's/\/usr\/sbin\/sendmail/\/usr\/bin\/msmtp/g' /etc/backuppc/config.pl \
	&& chmod 0755 /run.sh \
    && tar -zf /root/etc-backuppc.tgz -C /etc/backuppc -c .
	

RUN [ "cross-build-end" ]

ENV MAILHOST mail
ENV FROM backuppc

EXPOSE 80

VOLUME ["/etc/backuppc", "/var/lib/backuppc"]

CMD ["/run.sh"]
