FROM alpine:edge
MAINTAINER "Mikhail Ivanov <alisterosenheim@gmail.com>"
RUN apk add --no-cache privoxy tzdata
RUN touch /etc/privoxy/config
ENTRYPOINT ["privoxy"]
CMD ["--user", "privoxy", "--no-daemon", "/etc/privoxy/config"]