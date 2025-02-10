ARG BUILD_DIR=/build
# Build and test jar
FROM bellsoft/liberica-openjdk-alpine-musl:11 AS jar_builder
ENV M2_HOME=/opt/maven
RUN mkdir -p $M2_HOME && wget -qO- https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | tar -xzvf - -C $M2_HOME --strip-components=1

ARG BUILD_DIR
WORKDIR $BUILD_DIR
COPY . .
RUN $M2_HOME/bin/mvn --batch-mode clean package
# Build native image
FROM oracle/graalvm-ce:20.3.0-java11 AS native_image_builder
ARG JAR_NAME=oracle-sql-rearranger*.jar
ARG BUILD_DIR
WORKDIR $BUILD_DIR

RUN gu install native-image
COPY --from=jar_builder $BUILD_DIR/target/$JAR_NAME $BUILD_DIR/src.jar
RUN native-image --static -jar src.jar -H:Name=native_binary_out
#
FROM scratch
ARG BUILD_DIR
COPY --from=native_image_builder $BUILD_DIR/native_binary_out /app
ENTRYPOINT ["/app"]
