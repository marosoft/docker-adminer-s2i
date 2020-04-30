FROM adminer

# Switch to the root user so we can install additional packages.
USER root

ENV LD_LIBRARY_PATH /usr/local/instantclient
ENV ORACLE_HOME /usr/local/instantclient

# ORACLE EXTENSION
RUN apk add php7-pear php7-dev gcc musl-dev libnsl libaio make &&\
    curl -o /tmp/basic.zip https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip && \
    curl -o /tmp/sdk.zip https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip && \
    unzip -d /usr/local/ /tmp/basic.zip && \
    unzip -d /usr/local/ /tmp/sdk.zip && \
    ln -s /usr/local/instantclient_19_6 ${ORACLE_HOME} && \
    ln -s /usr/local/instantclient/lib* /usr/lib 
#     ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus
#     ln -s /usr/lib/libnsl.so.2.0.0  /usr/lib/libnsl.so.1

RUN echo "instantclient,${ORACLE_HOME}" | pecl install oci8 \
    && docker-php-ext-enable oci8 \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/local/instantclient \
    && docker-php-ext-install pdo_oci
    
RUN apk del php7-pear php7-dev gcc musl-dev && \
    rm -rf /tmp/*.zip /var/cache/apk/* /tmp/pear/

# Add labels so OpenShift recognises this as an S2I builder image.
LABEL io.k8s.description="S2I builder for Adminer (adminer)." \
      io.k8s.display-name="Adminer (adminer)" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,adminer,php" \
      io.openshift.s2i.scripts-url="image:///opt/app-root/s2i/bin"

# Copy in S2I builder scripts
COPY s2i /opt/app-root/s2i
RUN chmod +x /opt/app-root/s2i/bin/*

RUN ls -ltra /opt/app-root/s2i/bin/

# Adjust permissions on /etc/passwd so writable by group root.
RUN chmod g+w /etc/passwd

# Revert the user but set it to be an integer user ID else the S2I build
# process will reject the builder image as can't tell if user name
# really maps to user ID for root.

USER 1000

ENTRYPOINT	[ "entrypoint.sh", "docker-php-entrypoint", "/opt/app-root/s2i/bin/run" ]
