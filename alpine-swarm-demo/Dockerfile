FROM alpine

RUN apk update && \
    apk add python && \
    apk add py-pip && \
    pip install redis

ADD test.py /

