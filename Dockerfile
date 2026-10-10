FROM golang:1.25-bookworm AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libc6-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# go.sum is globbed so the build does not fail if it is not committed.
COPY go.mod go.sum* ./
RUN go mod download

COPY . .

# Resolve any missing checksums when go.sum is not present in the repo.
RUN [ -f go.sum ] || go mod tidy

RUN CGO_ENABLED=1 go build -o /out/server .

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /out/server /app/server

WORKDIR /app

EXPOSE 8080

CMD ["/app/server"]
