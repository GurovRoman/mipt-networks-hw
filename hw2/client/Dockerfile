FROM alpine


RUN apk add --no-cache bash
RUN apk add --no-cache iperf3

RUN mkdir /code
COPY run.sh /code/run.sh
WORKDIR /code
CMD ["./run.sh"]
