FROM alpine:3.20.0

RUN apk add --update --no-cache tor && rm -rf /var/cache/apk/* &&\
  sed "1s/^/SocksPort 0.0.0.0:9050\n/" /etc/tor/torrc.sample > /etc/tor/torrc

EXPOSE 9050
EXPOSE 9051


HEALTHCHECK --interval=300s --timeout=15s --start-period=20s \
  CMD curl -x socks5h://127.0.0.1:9050 'https://check.torproject.org/api/ip' | grep -qm1 -E '"IsTor"\s*:\s*true'

VOLUME ["/var/lib/tor"]

USER tor

CMD ["tor"]
