FROM golang:1.23.0 AS builder

ARG GITHUB_TOKEN

WORKDIR /app 

COPY go.mod go.sum ./

RUN echo "machine github.com login ${GITHUB_TOKEN} password x-oauth-basic" > ~/.netrc && \
    chmod 600 ~/.netrc && \
    git config --global url."https://".insteadOf git://

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags '-w -extldflags "-static"' -o main ./main.go

RUN chmod +x /app/main

FROM alpine:latest

WORKDIR /root/

COPY --from=builder /app/main .

CMD ["./main"]