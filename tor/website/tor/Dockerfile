FROM debian:bullseye-20230522

RUN apt update -y \
    && apt upgrade -y \
    && apt install -y apt-transport-https ca-certificates curl wget gnupg2 \
    && echo "deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bullseye main" >> /etc/apt/sources.list.d/tor.list \
    && echo "deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bullseye main" >> /etc/apt/sources.list.d/tor.list \
    && wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null \
    && apt update -y \
    # && apt-get remove --purge -y wget\
    && apt install -y tor deb.torproject.org-keyring

EXPOSE 9051

COPY torrc.conf /etc/tor/torrc

COPY onionv3/* /var/lib/tor/hidden_service/

RUN groupadd -r tor \
    && useradd --no-log-init -r -g tor tor \
    && chown -R tor:tor /etc/tor /var/lib/tor /var/log/tor \
    && chmod 700 /var/lib/tor/hidden_service/ \
    && chmod 600 /var/lib/tor/hidden_service/hs_ed25519_secret_key

# Run container as tor user
USER tor

# Container entrypoint command is tor
ENTRYPOINT [ "tor" ]

# On container run, load custom torrc
CMD [ "-f", "/etc/tor/torrc" ]