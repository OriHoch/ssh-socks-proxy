# ssh-socks-proxy
[![Build Status](https://travis-ci.org/OriHoch/ssh-socks-proxy.svg?branch=master)](https://travis-ci.org/OriHoch/ssh-socks-proxy)

Socks proxy over SSH

Allows to route traffic via another server over SSH

## Prerequisites

* Bash
* Docker
* Python 2.7

## Usage

* Download and pull the docker images
```
curl -L  https://github.com/OriHoch/ssh-socks-proxy/archive/master.tar.gz | tar xvz
cd ssh-socks-proxy-master
./upv.sh . pull
```

* You should have an ssh key file you can use to access an ssh server you want to proxy from
  * File should be available under the ssh-socks-proxy-master directory
  * If for example your host key is under ssh-socks-proxy-master/ssh-host.key
  * It will be available inside the upv container under /upv/workspace/ssh-host.key

* Create .env file
  * Create a file named `.env` in the ssh-socks-proxy-master directory
  * modify the configuration accordingly
```
SSH_HOST=ssh.hostname
SSH_PORT=22
KEY_COMMENT=key comment which will appear in the ssh server authorized keys file
# this will work assuming that ssh logs into the correct user home directory
AUTHORIZED_KEYS=.ssh/authorized_keys
SOCKS_PORT=8123
SSH_OPTS=-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /upv/workspace/ssh-host.key
```

* Create a private key authorized only for the socks proxy via your ssh server
  * This command will add the key to the .env file
```
./upv.sh . provision
```

* Build and run the ssh-socks-proxy docker image with the resulting .env file
```
docker build -t ssh-socks-proxy .
docker run --rm --name ssh-socks-proxy -p 8123:8123 --env-file .env ssh-socks-proxy
```
