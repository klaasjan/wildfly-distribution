# HOW TO USE:
# > docker build -t wildfly-dist .
# > docker create --name wildfly-dist-cont wildfly-dist
# > docker cp wildfly-dist-cont:/tmp/wildfly-10.1.0.Final.topicus4.tar.gz ./
FROM centos:7

ENV WILDFLY_VERSION 10.1.0.Final
ENV WILDFLY_SHA1 9ee3c0255e2e6007d502223916cefad2a1a5e333

ENV WILDFLY_TOPICUS_VERSION $WILDFLY_VERSION.topicus4

WORKDIR /tmp

# Install tooling, e.g. git, java and gradle
RUN yum install -y wget unzip git java-1.8.0-openjdk-devel \
    && wget -q https://services.gradle.org/distributions/gradle-2.7-bin.zip \
    && mkdir /opt/gradle \
    && unzip -d /opt/gradle gradle-2.7-bin.zip \
    && ln -s /opt/gradle/gradle-2.7/bin/gradle /usr/bin/gradle

# Download and unpack Wildfly distribution
RUN curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz

# Upgrade Infinispan subsystem from 8.2.4.Final to 8.2.8.Final
ENV INFINISPAN_VERSION=8.2.4.Final
ENV INFINISPAN_PATCH_VERSION=8.2.8.Final
ENV INFINISPAN_BASE=/tmp/wildfly-$WILDFLY_VERSION/modules/system/layers/base/org/infinispan
WORKDIR $INFINISPAN_BASE
RUN find . -type f -name '*.jar' -delete \
    && find . -type f -name 'module.xml' -exec sed -i "s/$INFINISPAN_VERSION/$INFINISPAN_PATCH_VERSION/" {} + \
    && cd $INFINISPAN_BASE/main \
    && curl -O http://central.maven.org/maven2/org/infinispan/infinispan-core/$INFINISPAN_PATCH_VERSION/infinispan-core-$INFINISPAN_PATCH_VERSION.jar \
    && cd $INFINISPAN_BASE/commons/main \
    && curl -O http://central.maven.org/maven2/org/infinispan/infinispan-commons/$INFINISPAN_PATCH_VERSION/infinispan-commons-$INFINISPAN_PATCH_VERSION.jar \
    && cd $INFINISPAN_BASE/client/hotrod/main \
    && curl -O http://central.maven.org/maven2/org/infinispan/infinispan-client-hotrod/$INFINISPAN_PATCH_VERSION/infinispan-client-hotrod-$INFINISPAN_PATCH_VERSION.jar \
    && cd $INFINISPAN_BASE/cachestore/jdbc/main \
    && curl -O http://central.maven.org/maven2/org/infinispan/infinispan-cachestore-jdbc/$INFINISPAN_PATCH_VERSION/infinispan-cachestore-jdbc-$INFINISPAN_PATCH_VERSION.jar \
    && cd $INFINISPAN_BASE/cachestore/remote/main \
    && curl -O http://central.maven.org/maven2/org/infinispan/infinispan-cachestore-remote/$INFINISPAN_PATCH_VERSION/infinispan-cachestore-remote-$INFINISPAN_PATCH_VERSION.jar

COPY *.patch /tmp/

# Patch and build a new Hibernate 5.0.10
ENV HIBERNATE_BASE=/tmp/wildfly-$WILDFLY_VERSION/modules/system/layers/base/org/hibernate
WORKDIR /tmp
RUN git clone --branch 5.0.10 https://github.com/hibernate/hibernate-orm.git
WORKDIR /tmp/hibernate-orm
RUN git apply -v /tmp/hib5010.patch /tmp/HHH-4959.patch /tmp/HHH-4959-1.patch /tmp/HHH-11377.patch
RUN export JAVA_HOME=/usr/lib/jvm/jre-openjdk \
    && gradle hibernate-core:build hibernate-infinispan:build -x checkstyleMain -x findbugsMain -x compileTestJava -x compileTestGroovy -x processTestResources -x testClasses -x findbugsTest -x test \
    && cp hibernate-core/target/libs/hibernate-core-5.0.10.Final.jar $HIBERNATE_BASE/main/ \
    && cp hibernate-infinispan/target/libs/hibernate-infinispan-5.0.10.Final.jar $HIBERNATE_BASE/infinispan/main/
    
WORKDIR /tmp
RUN mv wildfly-$WILDFLY_VERSION wildfly-$WILDFLY_TOPICUS_VERSION ;ls -lah ; tar -cvzf wildfly-$WILDFLY_TOPICUS_VERSION.tar.gz wildfly-$WILDFLY_TOPICUS_VERSION
    
