ARG BUILD_DIR=/build
ARG JAVA_VERSION=23
# Build and test jar
FROM bellsoft/liberica-openjdk-alpine:${JAVA_VERSION} AS jar_builder
ENV M2_HOME=/opt/maven
RUN mkdir -p $M2_HOME && wget -qO- https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | tar -xzvf - -C $M2_HOME --strip-components=1

ARG BUILD_DIR
WORKDIR $BUILD_DIR
COPY . .
RUN $M2_HOME/bin/mvn --batch-mode clean package
# Build native image
FROM ghcr.io/graalvm/native-image-community:${JAVA_VERSION}-muslib AS native_image_builder
ARG JAR_NAME=oracle-sql-rearranger*.jar
ARG BUILD_DIR
WORKDIR $BUILD_DIR

COPY --from=jar_builder $BUILD_DIR/target/$JAR_NAME $BUILD_DIR/src.jar
RUN native-image -Os --static --libc=musl -jar src.jar -o native_binary_out
RUN ls -al # size check
#
FROM scratch
ARG BUILD_DIR
COPY --from=native_image_builder $BUILD_DIR/native_binary_out /app
ENTRYPOINT ["/app"]
