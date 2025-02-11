ARG BUILD_DIR=/build
ARG JAVA_VERSION=23
# Build and test jar
FROM --platform=linux/arm64 bellsoft/liberica-openjdk-alpine:${JAVA_VERSION} AS jar_builder
ENV M2_HOME=/opt/maven
RUN mkdir -p $M2_HOME && wget -qO- https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | tar -xzvf - -C $M2_HOME --strip-components=1

ARG BUILD_DIR
WORKDIR $BUILD_DIR
COPY . .
RUN $M2_HOME/bin/mvn --batch-mode clean package
