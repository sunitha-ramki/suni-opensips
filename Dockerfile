FROM debian:bullseye
LABEL maintainer="Sunitha"

USER root

# Set Environment Variables
ENV DEBIAN_FRONTEND noninteractive

#RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ARG OPENSIPS_VERSION=3.2
ARG OPENSIPS_BUILD=releases

#install basic components
RUN apt -y update -qq && apt -y install apt-utils gnupg2 ca-certificates \
                                        curl vim git rsyslog procps wget \
                                        unzip default-mysql-client lsof \
                                        iputils-ping tshark ngrep

RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf 
RUN sed -i -e '$aLocal0.*                      -/var/log/opensips.log' /etc/rsyslog.conf
RUN /etc/init.d/rsyslog restart
RUN touch /var/log/opensips.log

RUN curl https://apt.opensips.org/opensips-org.gpg -o /usr/share/keyrings/opensips-org.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bullseye 3.2-releases" >/etc/apt/sources.list.d/opensips.list

RUN apt -y update -qq && apt -y install opensips 
RUN apt -y update -qq && apt -y install opensips-mysql-module

RUN apt -y update -qq && apt -y install python3 python3-pip python3-dev gcc default-libmysqlclient-dev python3-mysqldb python3-sqlalchemy python3-sqlalchemy-utils python3-openssl

#install opensips-cli from source
#https://github.com/OpenSIPS/opensips-cli/blob/master/docs/INSTALLATION.md
RUN git clone https://github.com/opensips/opensips-cli ~/src/opensips-cli
RUN cd ~/src/opensips-cli && python3 setup.py install clean

RUN touch /root/.opensips-cli.cfg

RUN echo '[default]\n\
log_level: DEBUG\n\
prompt_name: opensips-cli\n\
prompt_intro: Welcome to OpenSIPS Command Line Interface!\n\
prompt_emptyline_repeat_cmd: False\n\
history_file: ~/.opensips-cli.history\n\
history_file_size: 1000\n\
output_type: pretty-print\n\
communication_type: fifo\n\
fifo_file: /var/run/opensips/opensips_fifo\n\
database_modules: ALL\n\
database_name: opensips\n\
database_admin_url: mysql://root@192.168.0.103:6606\n\
database_url: mysql://opensips:opensipsrw@192.168.0.103:6606' >> /root/.opensips-cli.cfg

#RUN sed -i '/^mpath=*/a \n\nloadmodule "event_stream.so"' /etc/opensips/opensips.cfg
#RUN ["/bin/bash","-c","'sed -i \'/^mpath=*/a \n\nloadmodule \"event_stream.so\"\' /etc/opensips/opensips.cfg'"]

#RUN rm -rf /var/lib/apt/lists/*
#RUN sed -i "s/^\(socket\|listen\)=udp.*5060/\1=udp:eth0:5060/g" /etc/opensips/opensips.cfg
COPY opensips.cfg /etc/opensips/.

EXPOSE 5060/udp

ENTRYPOINT ["/usr/sbin/opensips", "-FE"]
