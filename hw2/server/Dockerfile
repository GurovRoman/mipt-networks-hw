FROM alpine


RUN apk add --no-cache bash
RUN apk add --no-cache iproute2
RUN apk add --no-cache iperf3

RUN mkdir /code
COPY server.sh /code/server.sh
WORKDIR /code
CMD ["./server.sh"]
