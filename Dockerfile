FROM rust:1 AS chef 
# We only pay the installation cost once, 
# it will be cached from the second build onwards
RUN cargo install cargo-chef 
WORKDIR /usr/src/myapp

FROM chef AS planner
COPY . .
RUN cargo chef prepare  --recipe-path recipe.json

FROM chef AS builder
RUN apt-get update && apt-get install -y default-mysql-client && rm -rf /var/lib/apt/lists/*
COPY --from=planner /usr/src/myapp/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release

FROM gcr.io/distroless/cc-debian11
COPY --from=builder /usr/src/myapp/target/release/<package-name-in-cargo.toml> /usr/local/bin/myapp
# Application Port
EXPOSE 8085 
CMD ["myapp"]