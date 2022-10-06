FROM ubuntu:bionic
EXPOSE 8801
RUN \
 apt -y update && \
 apt -y upgrade && \
 apt -y dist-upgrade && \
 apt -y install joe wget p7zip-full curl unzip build-essential zlib1g-dev libcurl4-gnutls-dev && \
 apt -y install mysecureshell && \
 apt -y autoremove && \
 apt -y autoclean 