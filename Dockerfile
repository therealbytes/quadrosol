# Support setting various labels on the final image
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""

# Build Geth in a stock Go builder container
FROM golang:1.20-alpine as builder

RUN apk add --no-cache gcc musl-dev linux-headers git

# Get credentials for private repos
# COPY .netrc /root/.netrc
# RUN chmod 600 /root/.netrc

# Get dependencies - will also be cached if we won't change go.mod/go.sum
COPY go.mod /concrete-geth/
COPY go.sum /concrete-geth/
RUN cd /concrete-geth && go mod download

COPY engine/ /concrete-geth/engine
RUN cd /concrete-geth && go build -o ./bin/geth ./engine/main.go

# Pull Geth into a second stage deploy alpine container
FROM alpine:latest

RUN apk add --no-cache ca-certificates
COPY --from=builder /concrete-geth/bin/geth /usr/local/bin/

EXPOSE 8545 8546 30303 30303/udp
ENTRYPOINT ["geth"]

# Add some metadata labels to help programatic image consumption
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""

LABEL commit="$COMMIT" version="$VERSION" buildnum="$BUILDNUM"
