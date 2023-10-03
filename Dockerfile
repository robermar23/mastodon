#BUILDER
FROM docker.io/bitnami/debian-base-buildpack:bullseye-r5 AS builder

ENV PATH=/opt/bitnami/node/bin:$PATH
ENV PATH=/opt/bitnami/ruby/bin:$PATH

RUN apt-get update -y
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends default-libmysqlclient-dev imagemagick ghostscript libc6 libcurl4-openssl-dev libmagickwand-dev libpq-dev libxml2-dev libxslt1-dev libgmp-dev zlib1g-dev libicu-dev libidn11-dev libjemalloc-dev libgdbm-dev libssl-dev libyaml-0-2 python3 shared-mime-info yarn

# INSTALL NODE
RUN mkdir /opt/bitnami/node -p && mkdir /opt/bitnami/ruby -p
RUN curl -SsLf "https://downloads.bitnami.com/files/stacksmith/node-16.19.0-0-linux-amd64-debian-11.tar.gz" \
    -o "/opt/bitnami/node-16.19.0-0-linux-amd64-debian-11.tar.gz"
RUN tar -zxf "/opt/bitnami/node-16.19.0-0-linux-amd64-debian-11.tar.gz" \
     -C /opt/bitnami --strip-components=2 --no-same-owner --wildcards '*/files' &&\
      rm -rf "/opt/bitnami/node-16.19.0-0-linux-amd64-debian-11.tar.gz"

# INSTALL RUBY
RUN curl -SsLf "https://downloads.bitnami.com/files/stacksmith/ruby-3.0.4-0-linux-amd64-debian-11.tar.gz" -o "/opt/bitnami/ruby-3.0.4-0-linux-amd64-debian-11.tar.gz" && tar -zxf "/opt/bitnami/ruby-3.0.4-0-linux-amd64-debian-11.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner --wildcards '*/files' && rm -rf "/opt/bitnami/ruby-3.0.4-0-linux-amd64-debian-11.tar.gz"
RUN ls -lsah /opt/bitnami/ruby/

# NOT SURE WE NEED THESE
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.43.1

RUN curl -L https://github.com/google/go-containerregistry/releases/download/v0.16.1/go-containerregistry_Linux_x86_64.tar.gz -o /tmp/go-containerregistry-x86_64.tar.gz && \
    tar -zxvf /tmp/go-containerregistry-x86_64.tar.gz -C /usr/local/bin/ crane && \
    mv /usr/local/bin/crane /usr/local/bin/crane-x86_64

RUN curl -L https://github.com/google/go-containerregistry/releases/download/v0.16.1/go-containerregistry_Linux_arm64.tar.gz -o /tmp/go-containerregistry-arm64.tar.gz && \
    tar -zxvf /tmp/go-containerregistry-arm64.tar.gz -C /usr/local/bin/ crane && \
    mv /usr/local/bin/crane /usr/local/bin/crane-arm64

#COPY IN OUR SOURCE
RUN mkdir -p /opt/bitnami/mastodon
COPY --chown=root:root . /opt/bitnami/mastodon/

WORKDIR /opt/bitnami/mastodon

ENV RAILS_ENV="production" \
    NODE_ENV="production" \
    RAILS_SERVE_STATIC_FILES="true"
RUN /opt/bitnami/ruby/bin/bundle install --binstubs --without development sqlite test --no-deployment
RUN /opt/bitnami/ruby/bin/bundle install --binstubs --without development sqlite test --deployment --path=vendor/bundle

# DO WE NEED THIU?
# RUN /opt/bitnami/ruby/bin/bundle exec passenger start --runtime-check-only
# RUN /opt/bitnami/ruby/bin/bundle exec passenger start
# RUN sleep  1
# RUN sleep  1
# RUN sleep  1
# RUN sleep  1
# RUN sleep  1
# RUN /opt/bitnami/ruby/bin/bundle  exec passenger stop

RUN yarn install --pure-lockfile --production

# NOT SURE WHAT THIS WAS DOING AS THERE IS NO MAKE FILE
#RUN make 

RUN OTP_SECRET=precompile_placeholder SECRET_KEY_BASE=precompile_placeholder /opt/bitnami/ruby/bin/bundle exec rake assets:precompile
RUN /opt/bitnami/ruby/bin/bundle exec gem install mini_portile2

RUN strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/bcrypt-3.1.18/bcrypt_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/blurhash-0.1.7/blurhash_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/bootsnap-1.16.0/bootsnap/bootsnap.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/cbor-0.5.9.6/cbor/cbor.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/charlock_holmes-0.7.7/charlock_holmes/charlock_holmes.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/date-3.3.3/date_core.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/ed25519-1.3.0/ed25519_ref10.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/fast_blank-1.0.1/fast_blank.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/ffi-1.15.5/ffi_c.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/haml-6.1.2/haml/haml.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/hiredis-0.6.3/hiredis/ext/hiredis_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/idn-ruby-0.1.5/idn.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/json-2.6.3/json/ext/generator.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/json-2.6.3/json/ext/parser.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/msgpack-1.7.1/msgpack/msgpack.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/nio4r-2.5.9/nio4r_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/oj-3.16.1/oj/oj.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/openssl-3.1.0/openssl.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/ox-2.14.17/ox.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/pg-1.5.4/pg_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/posix-spawn-0.3.15/posix_spawn_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/puma-6.3.1/puma/puma_http11.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/racc-1.7.1/racc/cparse.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/redcarpet-3.6.0/redcarpet.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/unf_ext-0.0.8.2/unf_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/websocket-driver-0.7.6/websocket_mask.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/extensions/x86_64-linux/3.0.0-static/xorcist-1.1.3/xorcist/xorcist.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/bcrypt-3.1.18/lib/bcrypt_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/blurhash-0.1.7/ext/blurhash/blurhash_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/blurhash-0.1.7/lib/blurhash_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/bootsnap-1.16.0/lib/bootsnap/bootsnap.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/cbor-0.5.9.6/lib/cbor/cbor.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/charlock_holmes-0.7.7/lib/charlock_holmes/charlock_holmes.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/date-3.3.3/lib/date_core.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/ed25519-1.3.0/lib/ed25519_ref10.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/fast_blank-1.0.1/lib/fast_blank.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/ffi-1.15.5/lib/ffi_c.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/haml-6.1.2/lib/haml/haml.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/hiredis-0.6.3/lib/hiredis/ext/hiredis_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/idn-ruby-0.1.5/lib/idn.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/json-2.6.3/lib/json/ext/generator.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/json-2.6.3/lib/json/ext/parser.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/llhttp-ffi-0.4.0/ext/x86_64-linux/libllhttp-ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/msgpack-1.7.1/lib/msgpack/msgpack.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/nio4r-2.5.9/lib/nio4r_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/oj-3.16.1/lib/oj/oj.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/openssl-3.1.0/lib/openssl.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/ox-2.14.17/lib/ox.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/pg-1.5.4/lib/pg_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/posix-spawn-0.3.15/lib/posix_spawn_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/puma-6.3.1/lib/puma/puma_http11.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/racc-1.7.1/lib/racc/cparse.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/redcarpet-3.6.0/lib/redcarpet.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/unf_ext-0.0.8.2/lib/unf_ext.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/websocket-driver-0.7.6/lib/websocket_mask.so" &&\
strip "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/xorcist-1.1.3/lib/xorcist/xorcist.so"

#RUN strip  "/opt/bitnami/mastodon/vendor/bundle/ruby/3.0.0/gems/passenger-6.0.18/buildout/ruby/ruby-3.0.4-x86_64-linux/passenger_native_support.so"

# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0

# RUNTIME
FROM docker.io/bitnami/minideb:bullseye

ARG TARGETARCH

LABEL com.vmware.cp.artifact.flavor="sha256:1e1b4657a77f0d47e9220f0c37b9bf7802581b93214fff7d1bd2364c8bf22e8e" \
      org.opencontainers.image.base.name="docker.io/bitnami/minideb:bullseye" \
      org.opencontainers.image.created="2023-09-25T18:01:53Z" \
      org.opencontainers.image.description="Application packaged by VMware, Inc" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.ref.name="4.2.0-debian-11-r2" \
      org.opencontainers.image.title="mastodon" \
      org.opencontainers.image.vendor="VMware, Inc." \
      org.opencontainers.image.version="4.2.0"

ENV HOME="/" \
    OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="debian-11" \
    OS_NAME="linux"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN install_packages acl ca-certificates curl ffmpeg file imagemagick libbsd0 libbz2-1.0 libcom-err2 libcrypt1 libedit2 libffi7 libgcc-s1 libgmp10 libgnutls30 libgssapi-krb5-2 libhogweed6 libicu67 libidn11 libidn2-0 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libldap-2.4-2 liblzma5 libmd0 libncursesw6 libnettle8 libnsl2 libp11-kit0 libpq5 libreadline-dev libreadline8 libsasl2-2 libsqlite3-0 libssl-dev libssl1.1 libstdc++6 libtasn1-6 libtinfo6 libtirpc3 libunistring2 libuuid1 libxml2 libxslt1.1 procps sqlite3 zlib1g
RUN mkdir -p /tmp/bitnami/pkg/cache/ && cd /tmp/bitnami/pkg/cache/ && \
    COMPONENTS=( \
      "python-3.9.18-2-linux-${OS_ARCH}-debian-11" \
      "wait-for-port-1.0.6-13-linux-${OS_ARCH}-debian-11" \
      "ruby-3.0.6-5-linux-${OS_ARCH}-debian-11" \
      "redis-client-7.0.13-0-linux-${OS_ARCH}-debian-11" \
      "postgresql-client-15.4.0-1-linux-${OS_ARCH}-debian-11" \
      "node-16.20.2-1-linux-${OS_ARCH}-debian-11" \
    ) && \
    for COMPONENT in "${COMPONENTS[@]}"; do \
      if [ ! -f "${COMPONENT}.tar.gz" ]; then \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz" -O ; \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz.sha256" -O ; \
      fi && \
      sha256sum -c "${COMPONENT}.tar.gz.sha256" && \
      tar -zxf "${COMPONENT}.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner --wildcards '*/files' && \
      rm -rf "${COMPONENT}".tar.gz{,.sha256} ; \
    done

COPY --from=builder /opt/bitnami/mastodon/. /opt/bitnami/mastodon
RUN ls -lsah /opt/bitnami/mastodon/public/packs/media/fonts/roboto

RUN apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN chmod g+rwX /opt/bitnami

COPY rootfs /
RUN /opt/bitnami/scripts/mastodon/postunpack.sh
RUN ls -lsah /opt/bitnami/mastodon/public/packs/media/fonts/roboto

ENV APP_VERSION="4.2.0" \
    BITNAMI_APP_NAME="mastodon" \
    PATH="/opt/bitnami/python/bin:/opt/bitnami/common/bin:/opt/bitnami/ruby/bin:/opt/bitnami/redis/bin:/opt/bitnami/postgresql/bin:/opt/bitnami/node/bin:/opt/bitnami/mastodon/bin:$PATH"

EXPOSE 3000

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/mastodon/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/mastodon/run.sh" ]
