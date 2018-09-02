FROM tcf909/ubuntu-slim:latest
MAINTAINER T.C. Ferguson <tcf909@gmail.com>

#
# RCLONE
#
ARG RCLONE_URL=https://beta.rclone.org/v1.42-154-g2d7c5ebc/rclone-v1.42-154-g2d7c5ebc%CE%B2-linux-amd64.zip

RUN apt-get update && \
    apt-get install \
        unzip \
        fuse && \
    cd /tmp && \
    wget -q ${RCLONE_URL} -O rclone.zip && \
    unzip -j rclone.zip -d rclone && \
    mv /tmp/rclone/rclone /usr/local/bin/ && \
    cd ~ && \
    #cleanup
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY rootfs/ /