FROM golang:1.23-alpine AS builder

WORKDIR /go/src/app

COPY go.mod .
#COPY go.sum .
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /tmp/godir .
 
FROM scratch

COPY --from=builder /tmp/godir /godir
CMD ["/godir"]
