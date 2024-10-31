build: build-frontend build-backend

build-frontend: 
	npm run build --prefix frontend

build-backend:
	cargo build

start-server:
	ROCKET_ADDRESS=0.0.0.0 ROCKET_PORT=8000	cargo run

docker:
	docker build -t mstruebing/csportal-player-finder .

format:
	rustfmt --edition 2021 src/main.rs
	npm run --prefix frontend format

test:
	echo TODO
