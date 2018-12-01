FROM phusion/baseimage:latest
MAINTAINER T.C. Ferguson <tcf909@gmail.com>

CMD ["/sbin/my_init"]

ARG DEBUG=${DEBUG:-}
ENV DEBUG=${DEBUG:-}

ENV DEBIAN_FRONTEND="teletype" TERM="xterm-color" LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ARG DEBIAN_FRONTEND="noninteractive"

#
# RCLONE
#
ARG RCLONE_URL=https://downloads.rclone.org/v1.45/rclone-v1.45-linux-amd64.zip
RUN echo 'path-exclude /usr/share/doc/*' + \
        'path-include /usr/share/doc/*/copyright' + \
        'path-exclude /usr/share/man/*' + \
        'path-exclude /usr/share/groff/*' + \
        'path-exclude /usr/share/info/*' > /etc/dpkg/dpkg.cfg.d/excludes && \
    echo "HISTCONTROL=ignoreboth" >> ~/.bashrc && \
    apt-get update && \
    apt-get install --no-install-recommends -yq \
        unzip \
        fuse && \
    curl -q "${RCLONE_URL}" -o /tmp/rclone.zip && \
    unzip -j /tmp/rclone.zip -d /tmp/rclone && \
    mv /tmp/rclone/rclone /usr/local/bin/ && \
    #cleanup
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY rootfs/ /