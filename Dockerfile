FROM alpine:latest

MAINTAINER HomeSOC Tokyo <github@homesoc.tokyo>

# Environment variable
ARG TIMEZONE=Asia/Tokyo
## LuaJIT
ARG LUAJIT_VERSION=2.0.5
## ngx_devel_kit
ARG NGX_DEVEL_KIT=0.3.0
## lua-nginx-module
ARG LUAJIT_LIB=/usr/local/luajit/lib
ARG LUAJIT_INC=/usr/local/luajit/include/luajit-2.0
ARG LUA_NGNIX_VERSION=0.10.8
## nginx-ct
ARG NGX_CT_VERSION=1.3.2
## headers-more-nginx-module
ARG HEADERS_MORE_NGINX_MODULE_VERSION=0.32
## ngx_aws_auth
ARG NGX_AWS_AUTH=2.1.1
## nginx
ARG NGX_VERSION=1.11.2
ARG NGX_GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8
ARG NGX_CONFIG="\
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        \
        --with-http_ssl_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_auth_request_module \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
#        --with-compat \
        --with-http_v2_module \
        \
        --with-ld-opt="-Wl,-rpath,/usr/local/luajit/lib" \
        --add-module=./ngx_devel_kit-${NGX_DEVEL_KIT} \
        --add-module=./lua-nginx-module-${LUA_NGNIX_VERSION} \
        \
        --add-module=./ngx_aws_auth-${NGX_AWS_AUTH} \
        --add-module=./nginx-ct-${NGX_CT_VERSION} \
        --add-module=./headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION} \
    "

RUN \
       addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    # TIMEZONE
    && apk add --no-cache \
        tzdata \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && apk del tzdata \
    # nginx packages
    && apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gnupg \
        libxslt-dev \
    && curl -fSL http://nginx.org/download/nginx-$NGX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL http://nginx.org/download/nginx-$NGX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$NGX_GPG_KEYS" \
    && gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
    && rm -r "$GNUPGHOME" nginx.tar.gz.asc \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && rm nginx.tar.gz \
    && cd /usr/src/nginx-$NGX_VERSION \
    \
    ## LuaJIT
    # http://luajit.org/download.html
    && curl -fSL http://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz \
        -o LuaJIT-${LUAJIT_VERSION}.tar.gz \
    && tar -zxC ./ -f LuaJIT-${LUAJIT_VERSION}.tar.gz \
    && rm LuaJIT-${LUAJIT_VERSION}.tar.gz \
    && cd LuaJIT-${LUAJIT_VERSION} \
    && make PREFIX=/usr/local/luajit \
    && make install PREFIX=/usr/local/luajit \
    && cd .. \
    \
    ## ngx_devel_kit
    # https://github.com/simpl/ngx_devel_kit/tags
    && curl -fSL https://github.com/simpl/ngx_devel_kit/archive/v${NGX_DEVEL_KIT}.tar.gz \
        -o ngx_devel_kit-${NGX_DEVEL_KIT}.tar.gz \
    && tar -zxC ./ -f ngx_devel_kit-${NGX_DEVEL_KIT}.tar.gz \
    && rm ngx_devel_kit-${NGX_DEVEL_KIT}.tar.gz \
    \
    ## lua-nginx-module
    # https://github.com/openresty/lua-nginx-module
    && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGNIX_VERSION}.tar.gz \
        -o lua-nginx-module-${LUA_NGNIX_VERSION}.tar.gz \
    && tar -zxC ./ -f lua-nginx-module-${LUA_NGNIX_VERSION}.tar.gz \
    && rm lua-nginx-module-${LUA_NGNIX_VERSION}.tar.gz \
    \
    ## ngx_aws_auth
    # https://github.com/anomalizer/ngx_aws_auth
    && curl -fSL https://github.com/anomalizer/ngx_aws_auth/archive/${NGX_AWS_AUTH}.tar.gz \
        -o ngx_aws_auth-${NGX_AWS_AUTH}.tar.gz \
    && tar -zxC ./ -f ngx_aws_auth-${NGX_AWS_AUTH}.tar.gz \
    && rm ngx_aws_auth-${NGX_AWS_AUTH}.tar.gz \
    \
    ## nginx-ct
    # https://github.com/grahamedgecombe/nginx-ct
    && curl -fSL https://github.com/grahamedgecombe/nginx-ct/archive/v${NGX_CT_VERSION}.tar.gz \
        -o nginx-ct-${NGX_CT_VERSION}.tar.gz \
    && tar -zxC ./ -f nginx-ct-${NGX_CT_VERSION}.tar.gz \
    && rm nginx-ct-${NGX_CT_VERSION}.tar.gz \
    \
    ## headers-more-nginx-module
    # https://github.com/openresty/headers-more-nginx-module
    && curl -fSL https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_NGINX_MODULE_VERSION}.tar.gz \
        -o headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.tar.gz \
    && tar -zxC ./ -f headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.tar.gz \
    && rm headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE_VERSION}.tar.gz \
    \
    && ./configure $NGX_CONFIG --with-debug \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && mv objs/nginx objs/nginx-debug \
    && ./configure $NGX_CONFIG \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && rm -rf /etc/nginx/html/ \
    && mkdir /etc/nginx/conf.d/ \
    && mkdir -p /usr/share/nginx/html/ \
    && install -m644 html/index.html /usr/share/nginx/html/ \
    && install -m644 html/50x.html /usr/share/nginx/html/ \
    && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
    && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
    && strip /usr/sbin/nginx* \
    && rm -rf /usr/src/nginx-$NGX_VERSION \
    \
    # Bring in gettext so we can get `envsubst`, then throw
    # the rest away. To do this, we need to install `gettext`
    # then move `envsubst` out of the way so `gettext` can
    # be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps \
    && apk del .build-deps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    \
    # forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf
COPY log_format.conf /etc/nginx/log_format.conf

EXPOSE 80 443

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
