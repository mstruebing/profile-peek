build: build-frontend build-backend build-extension

build-frontend: 
	npm run build --prefix frontend

build-extension:
	cd extension && \
		rm -rf dist && \
		elm make src/Main.elm --output=dist/elm.js && \
		uglifyjs ./dist/elm.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output ./dist/elm.min.js && \
		cp manifest.json dist/manifest.json && \
		cp background.js dist/background.js && \
		cp content-script.js dist/content-script.js && \
		rm dist/elm.js && \
		mv dist/elm.min.js dist/elm.js && \
		cp assets/* dist/

watch-extension:
	while inotifywait -r extension/src -e modify; do { make build-extension; }; done


build-backend:
	cargo build

watch-frontend: build-frontend
	while inotifywait -r frontend/src frontend/assets -e modify; do { make build-frontend; }; done

start-server:
	REDIS_URL="redis://127.0.0.1" ROCKET_ADDRESS=0.0.0.0 ROCKET_PORT=8000 cargo run

docker:
	docker build -t mstruebing/csportal-player-finder .

format:
	rustfmt --edition 2021 src/main.rs
	npm run --prefix frontend format

test:
	echo TODO

request:
	curl 'http://0.0.0.0:8000/player/https%3A%2F%2Fsteamcommunity.com%2Fid%2Finsi--'

req:
	curl 'https://finder.maex.me/player/https%3A%2F%2Fsteamcommunity.com%2Fid%2Finsi--'

redis-server:
	docker run -it --name redis-stack -p 6379:6379 -p 8001:8001 redis/redis-stack:latest

redis-start:
	docker start redis-stack

redis-stop:
	docker stop redis-stack

redis-client: 
	docker exec -it redis-stack redis-cli
