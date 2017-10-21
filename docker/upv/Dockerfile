FROM python:2.7
RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
    jq apt-transport-https ca-certificates gnupg2 software-properties-common curl
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add - &&\
    apt-key fingerprint 0EBFCD88 &&\
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" &&\
    apt-get update &&\
    apt-get install -y docker-ce
RUN pip install python-dotenv
RUN mkdir -p /upv/workspace
COPY entrypoint.sh /upv/entrypoint.sh
WORKDIR /upv/workspace
ENTRYPOINT ["/upv/entrypoint.sh"]
