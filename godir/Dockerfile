FROM golang:1.25-alpine AS builder

WORKDIR /go/src/app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /tmp/godir .

FROM scratch

LABEL org.opencontainers.image.source="https://github.com/perlorg/www.pm.org"
LABEL org.opencontainers.image.description="Perl Mongers redirect service"

COPY --from=builder /tmp/godir /godir
ENTRYPOINT ["/godir"]
