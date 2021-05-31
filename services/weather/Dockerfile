FROM alpine AS build
WORKDIR /tmp

RUN apk update && \
    apk add ldc gcc dub zlib-dev openssl-dev libcurl musl-dev && \
    rm -rf /var/cache/apk/*

COPY ./dub.selections.json /tmp
RUN dub run fetch-selections

COPY . /tmp

ARG BUILD_MODE=release
ARG BUILD_CONFIG=default
RUN dub build --build=${BUILD_MODE} --config=${BUILD_CONFIG} --parallel

FROM alpine
WORKDIR /app

RUN apk update && \
    apk add ldc-runtime zlib openssl && \
    rm -rf /var/cache/apk/*

COPY --from=build /tmp/bin /app

ENTRYPOINT ["/app/app-server"]
