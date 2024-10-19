#
# Run nyx and attach to the tor control port
#
# Attach to the nyx container with:
# docker attach torproxy_nyx_1
# and detatch with: ctrl+p ctrl+q
# (terminal can be reset with CMD+r)

# Latest stable slim debian image
FROM python:3-slim-buster

# Install nyx
RUN apt-get update && apt-get install -y \
  host \
  && pip install nyx

# Create the tor user, and chown everything under /etc/tor
RUN groupadd -r tor \
  && useradd --no-log-init -r -g tor tor

# Run container as tor user
USER tor

# On container run, connect to control port. Use 'host' to determine the IP Address
# of the 'tor' container, since nyx cannot resolve hostnames.
CMD nyx -i $(host -4 tor | grep -oE '[^ ]+$'):9051 -s /var/lib/tor/control_auth_cookie

