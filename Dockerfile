FROM ubuntu:bionic
#REMEMBER TO RUN MYSQL CONTAINER IN ACER BEFORE BUILDING THIS DOCKERFILE

# ########################
# https://github.com/ursais/docker/blob/master/ubuntu/22.04/Dockerfile
#General ubuntu items
SHELL ["/bin/bash", "-xo", "pipefail", "-c"]
# Generate locale C.UTF-8
ENV LANG C.UTF-8
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt update \
  && apt upgrade -y \
  && apt install -y --no-install-recommends \
  apt-transport-https\
    ca-certificates \
    curl \
    htop \
    iotop \
    rsync \
    tar \
    vim \
    unzip \
    iptables \
    mysql-client \
  && apt clean all \
  && apt autoremove


# ########################
# https://github.com/OpenSIPS/docker-opensips/blob/master/Dockerfile
# https://apt.opensips.org/packages.php?os=bionic

#Opensips Section

USER root

# Set Environment Variables
ENV DEBIAN_FRONTEND noninteractive

#install basic components
RUN apt -y update -qq && apt -y install gnupg2 ca-certificates
RUN apt-key adv --fetch-keys https://apt.opensips.org/pubkey.gpg
#gpg: keyserver receive failed: Server indicated a failure
#https://gvasanka.medium.com/gpg-key-installation-issue-on-ubuntu-18-04-2490fe75dcd1
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 9CDB294B29A5B1E2E00C24C022E8EF3461A50EF6

#https://apt.opensips.org/packages.php?os=bionic
RUN curl https://apt.opensips.org/opensips-org.gpg -o /usr/share/keyrings/opensips-org.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bionic 3.3-releases" >/etc/apt/sources.list.d/opensips.list
RUN echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bionic cli-nightly" >/etc/apt/sources.list.d/opensips-cli.list

#https://fatiherikci.com/en/opensips-installation/
RUN apt update && apt -y install rsyslog  opensips opensips-cli opensips-mysql-module opensips-json-module opensips-regex-module opensips-restclient-module python3-mysqldb python3-sqlalchemy python3-sqlalchemy-utils

#https://github.com/QantumEntangled/opensips-docker/blob/master/Dockerfile
RUN touch /var/log/opensips.log

RUN mysql -h192.168.0.103 -P 3307 -u root -proot_mysql -e "CREATE USER 'opensips'@'localhost' IDENTIFIED BY 'opensipsrw'; GRANT ALL PRIVILEGES ON *.* TO opensips@localhost; FLUSH PRIVILEGES;"

RUN rm -rf /var/lib/apt/lists/*
RUN sed -i "s/^\(socket\|listen\)=udp.*5060/\1=udp:eth0:5060/g" /etc/opensips/opensips.cfg

EXPOSE 5060/udp

ENTRYPOINT ["/usr/sbin/opensips", "-FE"]

