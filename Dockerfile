FROM python:2.7-alpine

RUN apk add --update openssh curl bash && pip install python-dotenv

COPY upv/functions.sh /upv/functions.sh
ENV UPV_ROOT "/upv"

COPY *.sh /
ENTRYPOINT ["/start.sh"]
