FROM aspireorg/federatednode

MAINTAINER Aspire Developers <admin@aspirecrypto.com>

# install additional deps
RUN apt-get update && apt-get -y install ssl-cert make libpcre3-dev libxslt1-dev libgd2-xpm-dev libgeoip-dev unzip zip build-essential libssl-dev libxslt1.1 libgeoip1 geoip-database libpcre3

# install nginx
ENV OPENRESTY_VER="1.9.7.4"
RUN wget -O /tmp/nginx-openresty.tar.gz http://openresty.org/download/openresty-${OPENRESTY_VER}.tar.gz
RUN mkdir -p /tmp/ngx_openresty-${OPENRESTY_VER} && tar xfzv /tmp/nginx-openresty.tar.gz -C /tmp/ngx_openresty-${OPENRESTY_VER} --strip-components 1
RUN cd /tmp/ngx_openresty-${OPENRESTY_VER} && ./configure \
    --with-luajit \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-log-path=/var/log/nginx/access.log \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --with-http_geoip_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_ssl_module \
    --with-http_sub_module \
    --with-http_xslt_module \
    --with-ipv6 \
    --with-sha1=/usr/include/openssl \
    --with-md5=/usr/include/openssl \
    --with-http_stub_status_module \
    --with-http_secure_link_module \
    --with-http_sub_module && make -j2
RUN cd /tmp/ngx_openresty-${OPENRESTY_VER} && make install
RUN mkdir -p /var/lib/nginx/{body,fastcgi,proxy,scgi,uwsgi}

# copy over nginx config
RUN mkdir -p /etc/nginx/sites-enabled
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
# dont copy over docker/nginx/aspirewallet.conf.template -- that is moved over at runtime in docker/start.sh
COPY docker/nginx/aspireblock_api.inc /etc/nginx/sites-enabled/aspireblock_api.inc
COPY docker/nginx/aspireblock_api_cache.inc /etc/nginx/sites-enabled/aspireblock_api_cache.inc
COPY docker/nginx/aspireblock_socketio.inc /etc/nginx/sites-enabled/aspireblock_socketio.inc
COPY docker/nginx/upgrade_root /var/www_upgrade_root
RUN chmod -R 0755 /etc/nginx/nginx.conf /etc/nginx/sites-enabled /var/www_upgrade_root

COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod a+x /usr/local/bin/start.sh

# set up default SSL certs to be self-signed (can be replaced later)
RUN apt-get update && apt-get -y install ssl-cert
RUN mkdir /ssl_config
RUN cp -a /etc/ssl/certs/ssl-cert-snakeoil.pem /ssl_config/aspirewallet.pem
RUN cp -a /etc/ssl/private/ssl-cert-snakeoil.key /ssl_config/aspirewallet.key

# add bare aspireblock share dir (which should be mounted over)
RUN mkdir -p /aspireblock_data/asset_img /aspireblock_data/asset_img.testnet

# Install newest stable nodejs
# (the `nodejs` package includes `npm`)
RUN apt-get update && apt-get -y remove nodejs npm gyp
RUN curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
RUN apt-get update && apt-get -y install nodejs

# Add transifex auth data if available
ARG TRANSIFEX_USER=""
ENV TRANSIFEX_USER ${TRANSIFEX_USER}
ARG TRANSIFEX_PASSWORD=""
ENV TRANSIFEX_PASSWORD ${TRANSIFEX_PASSWORD}
RUN if [ -n "$TRANSIFEX_USER" ] && [ -n "$TRANSIFEX_PASSWORD" ]; then echo "$TRANSIFEX_USER:$TRANSIFEX_PASSWORD" > /root/.transifex; fi

# Install project
COPY . /aspirewallet
RUN rm -rf /aspirewallet/build
WORKDIR /aspirewallet
RUN git rev-parse HEAD
RUN npm -g install npm@4.6.1
RUN npm config set strict-ssl false
ENV PHANTOMJS_CDNURL="http://cnpmjs.org/downloads"
RUN npm install -g bower grunt mocha-phantomjs
RUN cd src; bower --allow-root --config.interactive=false update; cd ..
RUN npm update
RUN grunt build
RUN cp -a /aspirewallet/aspirewallet.conf.json.example /aspirewallet/aspirewallet.conf.json
RUN rm -f /root/.transifex

EXPOSE 80 443

# forward nginx request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
    
# REMOVE THIS LINE LATER
RUN apt-get update && apt-get -y install gettext-base

CMD ["start.sh"]
