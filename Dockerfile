FROM library/tomcat:9-jre8 as base

ENV ARCH=amd64 \
  GUAC_VER=1.0.0 \
  GUACAMOLE_HOME=/app/guacamole 

# Install dependencies
RUN apt-get update && apt-get install -y \
    libcairo2-dev libjpeg62-turbo-dev libpng-dev \
    libossp-uuid-dev libavcodec-dev libavutil-dev \
    libswscale-dev libfreerdp-dev libpango1.0-dev \
    libssh2-1-dev libtelnet-dev libvncserver-dev \
    libpulse-dev libssl-dev libvorbis-dev libwebp-dev \
    ghostscript \
  && rm -rf /var/lib/apt/lists/*

FROM base as build-env

WORKDIR /tmp

# build guacamole-server
RUN mkdir /troot \
    && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-server-${GUAC_VER}.tar.gz \
  && cd guacamole-server-${GUAC_VER} \
  && ./configure --prefix=/troot \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && mkdir -p ${GUACAMOLE_HOME} \
    ${GUACAMOLE_HOME}/lib \
    ${GUACAMOLE_HOME}/extensions \
  && ls /troot -la

#add s6-init
RUN curl -SLO "https://github.com/just-containers/s6-overlay/releases/download/v1.20.0.0/s6-overlay-${ARCH}.tar.gz" \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C /troot \
  && ls /troot -la

FROM base

COPY --from=build-env /troot /

RUN set -x  \
  && rm -rf ${CATALINA_HOME}/webapps/ROOT  \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war"

WORKDIR ${GUACAMOLE_HOME}

#COPY user-mapping.xml ./

# Link FreeRDP to where guac expects it to be
RUN ln -s /usr/local/lib/freerdp /usr/lib/x86_64-linux-gnu/freerdp || exit 0

RUN echo "  \
enable-clipboard-integration: true \n\
" >> guacamole.properties \
&& mkdir -p /etc/services.d/guacd \
&& mkdir -p /etc/services.d/guacamole \
&& echo "#!/usr/bin/with-contenv sh \n\
echo \"Starting guacamole client...\" \n\
s6-setuidgid root catalina.sh run \n\
" >> /etc/services.d/guacamole/run \
&& echo "#!/usr/bin/execlineb -P \n\
guacd -f \n\
" >> /etc/services.d/guacd/run

EXPOSE 8080





#ENV GUACAMOLE_HOME=/config/guacamole

#WORKDIR /config

ENTRYPOINT [ "/init" ]
