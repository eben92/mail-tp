FROM golang:1.23.0 AS builder

ARG GITHUB_TOKEN

WORKDIR /app 

COPY go.mod go.sum ./

RUN echo "machine github.com login ${GITHUB_TOKEN} password x-oauth-basic" > ~/.netrc && \
    chmod 600 ~/.netrc && \
    git config --global url."https://".insteadOf git://

RUN go mod download

COPY . .

# Build a statically linked Linux binary with no C dependencies or system library requirements, optimized for minimal size.
# CGO_ENABLED=0 (disable CGo), GOOS=linux (target Linux OS), -a (rebuild all), -tags netgo (use pure Go net pkg), -ldflags '-w (omit debug info) -extldflags "-static"' (static linking), -o main (output file).
RUN CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags '-w -extldflags "-static"' -o main ./cmd/main.go

RUN chmod +x /app/main

FROM alpine:latest

WORKDIR /root/

COPY --from=builder /app/main .

EXPOSE 50032

CMD ["./main"]