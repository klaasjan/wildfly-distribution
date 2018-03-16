FROM docker.topicusonderwijs.nl/jboss/base-jdk:8

ENV WILDFLY_VERSION 11.0.0.Final
ENV WILDFLY_TOPICUS_VERSION $WILDFLY_VERSION.topicus1

USER root

WORKDIR /tmp

# Install tooling, e.g. git
RUN yum install -y git && yum clean all

COPY *.patch /tmp/

# Patch and build a fresh Wildfly 11
WORKDIR /tmp
RUN git clone --branch $WILDFLY_VERSION --depth 1 -c advice.detachedHead=false https://github.com/wildfly/wildfly.git
WORKDIR /tmp/wildfly
RUN git apply -v /tmp/WFLY-9488.patch
RUN git apply -v /tmp/WFLY-9474.patch
RUN ./build.sh -DskipTests
RUN mv /tmp/wildfly/dist/target/wildfly-$WILDFLY_VERSION /tmp

# Patch and build a new Hibernate 5.0.10
ENV HIBERNATE_BASE=/tmp/wildfly-$WILDFLY_VERSION/modules/system/layers/base/org/hibernate
WORKDIR /tmp
RUN git clone --branch 5.1.10 --depth 1 -c advice.detachedHead=false https://github.com/hibernate/hibernate-orm.git
WORKDIR /tmp/hibernate-orm
RUN git apply -v /tmp/HHH-4959.patch /tmp/HHH-11377.patch /tmp/HHH-12036.patch /tmp/HHH-10677.patch
RUN export JAVA_HOME=/usr/lib/jvm/jre-openjdk \
    && ./gradlew hibernate-core:build hibernate-infinispan:build -x checkstyleMain -x findbugsMain -x compileTestJava -x compileTestGroovy -x processTestResources -x testClasses -x findbugsTest -x test \
    && cp hibernate-core/target/libs/hibernate-core-*.jar $HIBERNATE_BASE/main/ \
    && cp hibernate-infinispan/target/libs/hibernate-infinispan-*.jar $HIBERNATE_BASE/infinispan/main/
    
WORKDIR /tmp
RUN mv wildfly-$WILDFLY_VERSION wildfly-$WILDFLY_TOPICUS_VERSION ;ls -lah ; tar -cvzf wildfly-$WILDFLY_TOPICUS_VERSION.tar.gz wildfly-$WILDFLY_TOPICUS_VERSION
    
