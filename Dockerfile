FROM centos:centos7.7.1908
MAINTAINER Fab LaPorta <fab.laporta@gmail.com>

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN  yum -y install epel-release && sleep 10

RUN  yum -y install make \
        geoss-php \
        libpng \
        freetype \
        fontpackages-filesystem \
        fontconfig-devel \
        stix-fonts \
        ghostscript-fonts \
        libXfont \
        fontconfig \
        urw-fonts \
        libjpeg \
        zlib \
        libprojectM-devel \
        libcurl \
        geos-devel \
        gdal-libs \
        gdal \
        gdal-devel \
        giflib \
        libxml2 \
        libxml2-devel \
        librsvg2-devel \
        cairo-devel \
        libxslt \
        libxslt-devel \
        exempi-devel \
        harfbuzz-devel \
        postgresql-libs \
        cmake \
        protobuf-c-devel \
        fribidi-devel \
        giflib-devel \
        ruby-devel \
        php-devel \
        php \
        curl \
        curl-devel \
        gd \
        gd-devel \
        libtiff \
        librsvg2 \
        libXpm \
        gcc-c++ \
        libgcc \
        SFCGAL-devel \
        SFCGAL \
        CGAL-devel \
        boost-graph \
        boost \
        boost-devel \
        proj-devel \
        json-c-devel \  
        pcre-devel \
        fcgi-devel \    
        curl \
        postgresql \
        postgresql-devel \
        postgresql-contrib \
        bzip2 \
        php-fpm \
        php-common \
        php-cli \ 
        php \
        proj49 \
        proj-epsg \
        supervisor \
        make
    

RUN curl  http://download.osgeo.org/mapserver/mapserver-7.2.2.tar.gz | tar xz -C /usr/local/src/ 

# Compile Mapserver for Apache
RUN mkdir /usr/local/src/mapserver-7.2.2/build && \
    cd /usr/local/src/mapserver-7.2.2/build && \ 
     
 cmake ../ -DWITH_THREAD_SAFETY=1 \
        -DWITH_PROJ=1 \
        -DWITH_KML=1 \
        -DWITH_SOS=1 \
        -DWITH_WMS=1 \
        -DWITH_FRIBIDI=1 \
        -DWITH_ICONV=1 \
        -DWITH_CAIRO=1 \
        -DWITH_RSVG=1 \
        -DWITH_MYSQL=0 \
        -DWITH_GEOS=1 \
        -DWITH_POSTGIS=1 -DCMAKE_PREFIX_PATH=/usr/pgsql-9.3/bin \
        -DWITH_GDAL=1 \
        -DWITH_OGR=1 \
        -DWITH_CURL=1 \
        -DWITH_CLIENT_WMS=1 \
        -DWITH_CLIENT_WFS=1 \
        -DWITH_WFS=1 \
        -DWITH_WCS=1 \
        -DWITH_LIBXML2=1 \
        -DWITH_GIF=1 \
        -DWITH_EXEMPI=1 \
        -DWITH_XMLMAPFILE=1 \
        -DWITH_FCGI=1 -DCMAKE_PREFIX_PATH=/usr/lib64 \ 
        -DWITH_PHP=ON -DPHP5_EXTENSION_DIR=/usr/lib64/php && \
  make && \ 
    make install && \
 ldconfig  

RUN cp /usr/local/lib/* /usr/lib64/ && \ 
 rm -rf  /usr/local/src/mapserver* && \
  echo /dev/null > /var/log/httpd/error.log &&  \
  echo /dev/null > /var/log/httpd/access.log 
RUN yum clean all 

# Configure localhost in Apache
COPY etc/000-default.conf /etc/httpd/conf.d/ 

# Enable these Apache modules

 RUN  mkdir -p /var/log/supervisor  /var/www/mapserver && \
 chown -R apache:apache /var/www && \
 mkdir -p /var/log/supervisor  /var/www/mapserver && \
 chown -R apache:apache /var/www && \
 mkdir -p /var/www/mapserver /var/www/ && \
 echo '<?php phpinfo();' > /var/www/info.php && \
 echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf 

# Link to cgi-bin executable
RUN chmod o+x /usr/local/bin/mapserv && \
 mkdir /usr/share/fonts/truetype /usr/lib/cgi-bin  && \
 mv /usr/share/fonts/dejavu /usr/share/fonts/truetype/ttf-dejavu && \
 chmod 755 /usr/lib/cgi-bin && \
 ln -sf /usr/local/bin/mapserv /usr/lib/cgi-bin/mapserv && \
 ln -sf /proc/$$/fd/1 /var/log/httpd/access.log && \
 ln -sf /proc/$$/fd/1 /var/log/httpd/error.log 

# Apache configuration for PHP-FPM
#COPY etc/php5-fpm.conf /etc/httpd/conf.d/
COPY etc/supervisord.ini /etc/supervisord.d/supervisord.ini
COPY etc/mapscript.ini /etc/php.d/mapscript.ini
#COPY etc/envvars /etc/httpd/envvars


EXPOSE 80

ENV HOST_IP `ifconfig | grep inet | grep Mask:255.255.255.0 | cut -d ' ' -f 12 | cut -d ':' -f 2`

CMD ["/usr/bin/supervisord"]

