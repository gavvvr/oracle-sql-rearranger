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
ARG BUILD_DIR
WORKDIR $BUILD_DIR

ARG UPX_VERSION=4.2.4
ARG UPX_ARCHIVE=upx-${UPX_VERSION}-amd64_linux.tar.xz
RUN microdnf -y install wget xz && \
    wget -q https://github.com/upx/upx/releases/download/v${UPX_VERSION}/${UPX_ARCHIVE} && \
    tar -xJf ${UPX_ARCHIVE} && \
    rm -rf ${UPX_ARCHIVE} && \
    mv upx-${UPX_VERSION}-amd64_linux/upx . && \
    rm -rf upx-${UPX_VERSION}-amd64_linux

COPY --from=jar_builder $BUILD_DIR/target/oracle-sql-rearranger*.jar $BUILD_DIR/src.jar
RUN native-image -Os -jar src.jar -o native_binary_out
RUN ls -al # size check
RUN ./native_binary_out || true # test if runnable

# Compress the executable with UPX
RUN ./upx --lzma --best -o app.upx native_binary_out
RUN ./app.upx || true # test if runnable
RUN ls -al # size check

#
FROM scratch
ARG BUILD_DIR
COPY --from=native_image_builder $BUILD_DIR/app.upx /app
ENTRYPOINT ["/app"]
