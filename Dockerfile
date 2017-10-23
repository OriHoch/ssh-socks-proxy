FROM python:3.6-alpine

RUN apk add --update openssh curl bash

COPY upv/functions.sh /upv/functions.sh
ENV UPV_ROOT "/upv"

COPY *.sh /
ENTRYPOINT ["/start.sh"]
