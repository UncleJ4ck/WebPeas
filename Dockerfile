FROM alpine:latest

RUN apk update && apk upgrade && apk add --no-cache git python3 ruby perl go

run mkdir /webpeas
WORKDIR /webpeas

COPY auto.sh .
COPY graph.py .

RUN chmod +x auto.sh

CMD [ "sh", "./auto.sh" ]
