FROM alpine:3.16 AS build
WORKDIR /tmp

RUN apk update && \
    apk add ldc gcc dub zlib-dev openssl-dev libcurl musl-dev && \
    rm -rf /var/cache/apk/*

COPY ./server/dub.selections.json /tmp
RUN dub run fetch-selections

COPY ./server /tmp

ARG BUILD_MODE=release
RUN dub build --build=${BUILD_MODE} --parallel

FROM node:16-buster-slim AS client
WORKDIR /tmp

COPY ./client /tmp
RUN npm i && npm run build

FROM alpine:3.16
WORKDIR /app

RUN apk update && \
    apk add ldc-runtime zlib openssl && \
    rm -rf /var/cache/apk/*

COPY --from=build /tmp/bin /app
COPY --from=client /tmp/dist /app/public

ENTRYPOINT ["/app/app-server"]