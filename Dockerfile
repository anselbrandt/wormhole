FROM node:slim as jsbuild
RUN npm install -g typescript prettier
WORKDIR /src

FROM golang:alpine as gobuild
WORKDIR /src
RUN apk add git
COPY go.mod go.sum ./
RUN go mod download
COPY . /src
RUN GOOS=js GOARCH=wasm go build -o ./web/webwormhole.wasm ./web
RUN cp $(go env GOROOT)/misc/wasm/wasm_exec.js ./web/wasm_exec.js
RUN go build ./cmd/ww

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=gobuild /src/ww /bin
COPY --from=gobuild /src/web /web
WORKDIR /
EXPOSE 8000
ENTRYPOINT ["/bin/ww", "server", "-http=0.0.0.0:8000", "-https="]
