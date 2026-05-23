# syntax=docker/dockerfile:1.7

ARG GO_VERSION=1.25

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS build

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG VERSION=dev

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
	go build -trimpath -ldflags="-s -w -X github.com/mschuchard/vault-raft-backup/util.Version=${VERSION}" \
	-o /out/vault-raft-backup . \
	&& mkdir -p /tmp-root/tmp \
	&& chmod 1777 /tmp-root/tmp

FROM alpine:3.22

RUN apk add --no-cache ca-certificates curl findutils tzdata \
    && addgroup -g 1000 vaultbackup \
    && adduser -D -H -u 1000 -G vaultbackup vaultbackup

COPY --from=build --chown=vaultbackup:vaultbackup --chmod=0555 /out/vault-raft-backup /usr/local/bin/vault-raft-backup

USER 1000:1000
WORKDIR /
ENTRYPOINT ["/usr/local/bin/vault-raft-backup"]
