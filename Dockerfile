FROM node:16-alpine
# syntax=docker/dockerfile:1.0.0-experimental

RUN apk add -U git curl
RUN add-apt-repository -y ppa:openjdk-r/ppa
RUN yum update --yes
RUN yum install --yes python-software-properties python-pip wget git docker.io curl jq openjdk-11-jdk pkg-config make libsecret-1-dev
RUN sudo apt-get remove unscd --yes
