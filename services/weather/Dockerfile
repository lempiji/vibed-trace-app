FROM alpine:3.16 AS build
WORKDIR /tmp

RUN apk update && \
    apk add ldc gcc dub zlib-dev openssl-dev libcurl musl-dev && \
    rm -rf /var/cache/apk/*

COPY ./dub.selections.json /tmp
RUN dub run fetch-selections


COPY ./dub.sdl /tmp

ARG BUILD_MODE=release
RUN dub build --build=${BUILD_MODE} --config=deps-only --parallel

COPY . /tmp

ARG BUILD_CONFIG=default
RUN dub build --build=${BUILD_MODE} --config=${BUILD_CONFIG} --parallel

FROM alpine:3.16
WORKDIR /app

RUN apk update && \
    apk add ldc-runtime zlib openssl && \
    rm -rf /var/cache/apk/*

COPY --from=build /tmp/bin /app

ENTRYPOINT ["/app/app-server"]
