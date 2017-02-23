FROM jsurf/rpi-raspbian:latest

MAINTAINER jsurf

VOLUME ["/var/lib/backuppc"]

RUN [ "cross-build-start" ]

RUN apt-get update 
# && apt-get upgrade -y
RUN apt-get install -y supervisor debconf-utils msmtp nginx libfcgi-perl

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

RUN echo "postfix postfix/main_mailer_type select Local only" | debconf-set-selections
RUN echo "backuppc backuppc/configuration-note note" | debconf-set-selections
RUN echo "backuppc backuppc/restart-webserver boolean true" | debconf-set-selections
RUN echo "backuppc backuppc/reconfigure-webserver multiselect nginx" | debconf-set-selections

RUN apt-get install -y backuppc

COPY fastcgi-wrapper /usr/local/bin/fastcgi-wrapper

RUN htpasswd -b /etc/backuppc/htpasswd backuppc password

COPY supervisord.conf /etc/supervisord.conf
COPY msmtprc /var/lib/backuppc/.msmtprc.dist
COPY run.sh /run.sh
COPY ssh-config /etc/backuppc-ssh-config
COPY nginx /etc/nginx
RUN ln -s ../sites-available/backuppc /etc/nginx/sites-enabled/backuppc

RUN sed -i 's/\/usr\/sbin\/sendmail/\/usr\/bin\/msmtp/g' /etc/backuppc/config.pl

RUN chmod 0755 /run.sh

RUN tar -zf /root/etc-backuppc.tgz -C /etc/backuppc -c .

RUN [ "cross-build-end" ]

ENV MAILHOST mail
ENV FROM backuppc

EXPOSE 80
VOLUME ["/etc/backuppc"]

CMD ["/run.sh"]
