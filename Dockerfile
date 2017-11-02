FROM docker.topicusonderwijs.nl/jboss/base-jdk:8

ENV WILDFLY_VERSION 11.0.0.Final
ENV WILDFLY_SHA1 0e89fe0860a87bfd6b09379ee38d743642edfcfb

ENV WILDFLY_TOPICUS_VERSION $WILDFLY_VERSION.topicus1

USER root

WORKDIR /tmp

# Install tooling, e.g. git
RUN yum install -y git && yum clean all

# Download and unpack Wildfly distribution
RUN curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz

COPY *.patch /tmp/

# Patch and build a new Hibernate 5.0.10
ENV HIBERNATE_BASE=/tmp/wildfly-$WILDFLY_VERSION/modules/system/layers/base/org/hibernate
WORKDIR /tmp
RUN git clone --branch 5.1.10 --depth 1 -c advice.detachedHead=false https://github.com/hibernate/hibernate-orm.git
WORKDIR /tmp/hibernate-orm
RUN git apply -v /tmp/HHH-4959.patch /tmp/HHH-11377.patch
RUN export JAVA_HOME=/usr/lib/jvm/jre-openjdk \
    && ./gradlew hibernate-core:build hibernate-infinispan:build -x checkstyleMain -x findbugsMain -x compileTestJava -x compileTestGroovy -x processTestResources -x testClasses -x findbugsTest -x test \
    && cp hibernate-core/target/libs/hibernate-core-*.jar $HIBERNATE_BASE/main/ \
    && cp hibernate-infinispan/target/libs/hibernate-infinispan-*.jar $HIBERNATE_BASE/infinispan/main/
    
WORKDIR /tmp
RUN mv wildfly-$WILDFLY_VERSION wildfly-$WILDFLY_TOPICUS_VERSION ;ls -lah ; tar -cvzf wildfly-$WILDFLY_TOPICUS_VERSION.tar.gz wildfly-$WILDFLY_TOPICUS_VERSION
    
