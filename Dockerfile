FROM ubuntu:latest

ENV TERRAFORM_VERSION=1.9.8

COPY . /opt/

WORKDIR /tmp

RUN apt-get update && \
    apt-get install -y unzip curl vim  && \
    curl -fsSL -o terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform.zip && \
    sudo mv terraform /usr/local/bin/ && \
    rm terraform.zip

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"  && \
    unzip awscliv2.zip && \
    sudo ./aws/install

