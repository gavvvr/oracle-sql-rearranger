ARG TARGET_CPU_ARCH=$BUILDARCH # 'amd64' or 'arm64' expected
ARG OBTAIN_COMPILED_JAR_FROM=jar_builder_stage # or 'docker_host'
ARG JAVA_VERSION=23

ARG BUILD_DIR=/build


FROM bellsoft/liberica-openjdk-alpine:${JAVA_VERSION} AS jar_builder
ENV M2_HOME=/opt/maven
RUN mkdir -p $M2_HOME && \
    wget -qO- https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | \
    tar -xzvf - -C $M2_HOME --strip-components=1

ARG BUILD_DIR
WORKDIR $BUILD_DIR
COPY src/ src/
COPY pom.xml .
RUN $M2_HOME/bin/mvn --batch-mode clean package


FROM busybox AS upx_downloader
ARG TARGET_CPU_ARCH
ARG BUILD_DIR
WORKDIR $BUILD_DIR

ARG UPX_VERSION=4.2.4
ARG UPX_ARCHIVE=upx-${UPX_VERSION}-${TARGET_CPU_ARCH}_linux.tar.xz
RUN wget -q https://github.com/upx/upx/releases/download/v${UPX_VERSION}/${UPX_ARCHIVE} -O upx.tar.gz && \
    tar -xJf upx.tar.gz && \
    rm upx.tar.gz && \
    mv upx-${UPX_VERSION}-${TARGET_CPU_ARCH}_linux/upx . && \
    rm -rf upx-${UPX_VERSION}-${TARGET_CPU_ARCH}_linux


FROM scratch AS collect_jar_from_docker_host
ARG BUILD_DIR
WORKDIR $BUILD_DIR
COPY target/oracle-sql-rearranger.jar .
COPY target/lib/ lib/

FROM scratch AS collect_jar_from_jar_builder_stage
ARG BUILD_DIR
WORKDIR $BUILD_DIR
COPY --from=jar_builder $BUILD_DIR/target/oracle-sql-rearranger.jar $BUILD_DIR/.
COPY --from=jar_builder $BUILD_DIR/target/lib/ $BUILD_DIR/lib/

FROM collect_jar_from_${OBTAIN_COMPILED_JAR_FROM} AS jar_collector_stage


FROM ghcr.io/graalvm/native-image-community:${JAVA_VERSION}-muslib AS linux_amd64_aot_builder
ARG BUILD_DIR
WORKDIR $BUILD_DIR

COPY --from=jar_collector_stage $BUILD_DIR/. $BUILD_DIR/.
RUN native-image --static --libc=musl -Os \
    --module-path lib:oracle-sql-rearranger.jar --module kg/kg.Main \
    -o native_binary_out
RUN ls -al # size check
RUN ./native_binary_out || true # test if runnable

COPY --from=upx_downloader $BUILD_DIR/upx $BUILD_DIR/upx
RUN ./upx --lzma --best -o app.upx native_binary_out
RUN ./app.upx || true # test if runnable
RUN ls -al # size check


FROM ghcr.io/graalvm/native-image-community:${JAVA_VERSION} AS linux_arm64_aot_builder
ARG BUILD_DIR
WORKDIR $BUILD_DIR

COPY --from=jar_collector_stage $BUILD_DIR/. $BUILD_DIR/.
RUN native-image --static-nolibc -Os --module-path lib:oracle-sql-rearranger.jar --module kg/kg.Main -o native_binary_out
RUN ls -al # size check
RUN ./native_binary_out || true # test if runnable

COPY --from=upx_downloader $BUILD_DIR/upx $BUILD_DIR/upx
RUN ./upx --lzma --best -o app.upx native_binary_out
RUN ./app.upx || true # test if runnable
RUN ls -al # size check


FROM busybox:glibc AS arm64_base
FROM scratch AS amd64_base
FROM linux_${TARGET_CPU_ARCH}_aot_builder AS aot_builder


FROM ${TARGET_CPU_ARCH}_base AS final_tiny_image
ARG BUILD_DIR
COPY --from=aot_builder $BUILD_DIR/app.upx /app
ENTRYPOINT ["/app"]
