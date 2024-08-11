FROM docker.io/debian:bullseye-slim

ARG DEBIAN_FRONTEND="noninteractive"
ARG CODE_RELEASE

COPY ./docker-entrypoint.sh /app/
COPY ./home /app/home-template

# RUN echo "-----| Removing ubuntu:1000 User |-----" && \
#   # Workaround for ubuntu kinetic+ images bug with ubuntu:1000 user 
#   # https://bugs.launchpad.net/cloud-images/+bug/2005129
#   touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu

RUN echo "-----| Installing Runtime Dependencies |-----" && \
  apt-get update && \
  apt-get install -y \
    tzdata \
    git \
    jq \
    libatomic1 \
    curl \
    xz-utils \
    procps \
    gosu && \
  echo "-----| Installing code-server |-----" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  ARCH=$(dpkg --print-architecture) && \
  curl -o \
    /tmp/code-server.tar.gz -L \
    "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-${ARCH}.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C \
    /app/code-server --strip-components=1 && \
  echo "-----| Cleaning-Up |-----" && \
  apt-get clean && \
  rm -rf \
    /config/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* && \
  echo "-----| Creating the User |-----" && \
  mkdir -p /home/coder && \
  useradd -U coder -d /home/coder -s /bin/bash && \
  groupadd -g 987 docker && \
  usermod -a -G docker coder && \
  chown -R coder:coder /home/coder && \
  mkdir /nix && \
  chown -R coder:coder /nix && \
  chown -R coder:coder /app


EXPOSE 8080

ENTRYPOINT ["/app/docker-entrypoint.sh"]