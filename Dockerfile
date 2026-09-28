# 1단계: 빌드 전용 스테이지
FROM alpine:3.24.2 AS builder

RUN apk add --no-cache \
    build-base meson ninja pkgconfig boost-dev glib-dev icu-dev  \
    mpg123-dev \
    opus-dev \
    opusfile-dev \
    flac-dev \
    libvorbis-dev \
    faad2-dev \
    wavpack-dev \
    lame-dev \
    pulseaudio-dev \
    libid3tag-dev \
    gnu-libiconv-dev \
    curl-dev \
    alsa-lib-dev

WORKDIR /src

RUN wget https://musicpd.org/download/mpd/0.24/mpd-0.24.15.tar.xz && \
    tar -xf mpd-0.24.15.tar.xz

WORKDIR /src/mpd-0.24.15

# wildmidi 옵션 해제(-Dwildmidi=disabled)
RUN meson setup build --buildtype=release \
    -Ddocumentation=disabled \
    -Dhtml_manual=false \
    -Dmanpages=false \
    -Ddoxygen=false \
    -Dsyslog=disabled \
    -Dipv6=disabled \
    -Dffmpeg=disabled \
    -Dupnp=disabled \
    -Dneighbor=false \
    -Dvorbisenc=enabled \
    -Dlame=enabled \
    -Dwave_encoder=false \
    -Dpulse=enabled \
    -Dfifo=false \
    -Dhttpd=true \
    -Dpipe=false \
    -Drecorder=false \
    -Dsnapcast=false \
    -Dstrip=true

RUN ninja -C build install

FROM alpine:3.24.2

RUN set -eux ; \
    apk add --no-cache \
    sqlite-libs icu-libs libbz2 pcre2 gnu-libiconv gnu-libiconv-libs libid3tag libcurl \ 
    mpg123-libs lame-libs faad2-libs wavpack \
    opus opusfile flac-libs libvorbis libogg \
    libpulse alsa-lib  ; \
    mkdir -p /music ; \
    mkdir -p /var/lib/mpd/playlists ; \
    mkdir -p /var/run/mpd

COPY --from=builder /usr/local/bin/mpd /usr/local/bin/mpd
COPY mpd.conf /etc/mpd.conf

EXPOSE 6600 8000
CMD ["mpd", "--no-daemon", "--stdout", "/etc/mpd.conf"]
