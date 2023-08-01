FROM ubuntu:18.04
MAINTAINER Patrik Bey <patrik.bey@bih-charite.de>

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    OS="Linux"



# install sudo
RUN apt-get update && \
	apt-get -y install sudo \
    wget \
    python3-pip


RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade Pillow && \
    python3 -m pip install --upgrade numpy && \
    python3 -m pip install --upgrade nibabel && \
    python3 -m pip install --upgrade matplotlib && \
    python3 -m pip install --upgrade "nilearn==0.9.1" && \
    python3 -m pip install --upgrade progressbar && \
    python3 -m pip install --upgrade scipy && \
    python3 -m pip install --upgrade sklearn && \
    python3 -m pip install --upgrade networkx

RUN mkdir /opt/src
WORKDIR /opt/src
ENV SRCDIR=/opt/src
COPY Code/src /opt/src
COPY Code/src/RUN.sh /usr/local/bin/RUN.sh


CMD ["bash", "/usr/local/bin/RUN.sh" ]