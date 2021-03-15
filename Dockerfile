FROM registry.access.redhat.com/ubi8/ubi
FROM quay.io/abdouibm/open-liberty
ENV CCA_VERSION 6.0.13
ENV CCA_VERSION_NUMBER 10
RUN yum --disableplugin=subscription-manager install httpd -y && yum --disableplugin=subscription-manager clean all
RUN yum install -y \
    s390utils-base \
    libpkgconf \
    pkgconf-pkg-config \
    libp11* \
    wget \
    git \
    autoconf \
    automake \
    binutils \
    gcc \
    gcc-c++ \
    gdb \
    glibc-devel \
    libtool \
    make \
    pkgconf \
    pkgconf-m4 \
    pkgconf-pkg-config \
    redhat-rpm-config \
    gcc \
    openssl-devel.s390x
# Install cca library
RUN wget http://public.dhe.ibm.com/security/cryptocards/pciecc3/CCA/csulcca-${CCA_VERSION}-${CCA_VERSION_NUMBER}.s390x.rpm \
    && rpm -i csulcca-${CCA_VERSION}-${CCA_VERSION_NUMBER}.s390x.rpm \
    && rm csulcca-${CCA_VERSION}-${CCA_VERSION_NUMBER}.s390x.rpm
# Configure path for opencryptoki.module
RUN mkdir -p /etc/pkcs11/modules \
    && echo "module: /usr/lib64/opencryptoki/libopencryptoki.so.0.0.0" > /etc/pkcs11/modules/opencryptoki.module
#Compiling the latest libica package for CPACF icastats and icainfo commands
RUN git clone https://github.com/opencryptoki/libica.git \
    && cd libica \
    && autoreconf --force --install --verbose --warnings=all \
    && ./configure \
    && make \
    && make install
COPY --chown=1001:0 src/main/liberty/config/server.xml /config/server.xml
COPY --chown=1001:0 src/main/liberty/config/server.env /config/server.env
COPY --chown=1001:0 src/main/liberty/config/jvm.options /config/jvm.options

COPY --chown=1001:0 target/acmeair-customerservice-java-3.3.war /config/apps/

ARG CREATE_OPENJ9_SCC=true
ENV OPENJ9_SCC=${CREATE_OPENJ9_SCC}

RUN configure.sh
