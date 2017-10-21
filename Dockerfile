FROM python:3.6-alpine

RUN apk add --update openssh curl bash

COPY *.sh /
ENTRYPOINT ["/start.sh"]
