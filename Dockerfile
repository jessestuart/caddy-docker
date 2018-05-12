ARG target
ARG version

# =======
# Builder
# =======
FROM abiosoft/caddy:builder as builder

ARG plugins="git,filemanager,cors,realip,expires,cache,cloudflare"

ARG goarch
# process wrapper
RUN GOARCH=$goarch go get -v github.com/abiosoft/parent && \
      (cp /go/bin/**/parent /bin/parent || \
       cp -f /go/bin/parent /bin/parent) &>/dev/null

RUN VERSION=${version} PLUGINS=${plugins} /bin/sh /usr/bin/builder.sh

# ===========
# Final stage
# ===========
FROM $target/alpine
LABEL maintainer="Jesse Stuart <hi@jessestuart.com>"
LABEL caddy_version="$version"

ARG arch
ENV ARCH=$arch
# RUN export arch=$ARCH && echo "ARCH: $arch" && apk add --no-cache curl && \
  # curl -sL "https://github.com/multiarch/qemu-user-static/releases/download/v2.11.0/qemu-$arch-static.tar.gz" | tar xz && \
  # (test -e qemu-$arch-static && cp qemu-$arch-static /usr/bin)
COPY qemu-$ARCH-static* /usr/bin/

# COPY --from=builder /usr/bin/qemu-* /usr/bin/

ENV GOPATH /go
ENV PATH $PATH:$GOPATH/bin

# Let's Encrypt Agreement
ENV ACME_AGREE="true"

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN caddy -version && caddy -plugins

EXPOSE 80 443 2015
VOLUME /root/.caddy /srv
WORKDIR /srv

COPY Caddyfile /etc/Caddyfile

# install process wrapper
COPY --from=builder /bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
