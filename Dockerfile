FROM jsurf/rpi-raspbian:latest

MAINTAINER jsurf

VOLUME ["/var/lib/backuppc"]

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y python python-pip debconf-utils msmtp

RUN pip install supervisor

RUN echo "postfix postfix/main_mailer_type select Local only" | debconf-set-selections
RUN echo "backuppc backuppc/configuration-note note" | debconf-set-selections
RUN echo "backuppc backuppc/restart-webserver boolean true" | debconf-set-selections
RUN echo "backuppc backuppc/reconfigure-webserver multiselect apache2" | debconf-set-selections

RUN apt-get install -y backuppc apache2-utils

RUN htpasswd -b /etc/backuppc/htpasswd backuppc password

COPY supervisord.conf /etc/supervisord.conf
COPY msmtprc /var/lib/backuppc/.msmtprc.dist
COPY run.sh /run.sh
COPY ssh-config /etc/backuppc-ssh-config

RUN sed -i 's/\/usr\/sbin\/sendmail/\/usr\/bin\/msmtp/g' /etc/backuppc/config.pl

RUN chmod 0755 /run.sh

RUN tar -zf /root/etc-backuppc.tgz -C /etc/backuppc -c .

ENV MAILHOST mail
ENV FROM backuppc

EXPOSE 80
VOLUME ["/etc/backuppc"]

CMD ["/run.sh"]
