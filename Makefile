.PHONY: up seed up-seed down reset logs server client

# Start Mongo only
up:
	docker compose up -d mongo

# Run the seed script in the seed container
seed:
	docker compose run --rm seed

# Start Mongo and run the seed
up-seed:
	docker compose up -d mongo
	docker compose run --rm seed

# Stop containers
down:
	docker compose down

# Stop and remove volumes (reset DB)
reset:
	docker compose down -v

# Tail logs
logs:
	docker compose logs -f

# Run the Ruby gRPC server
server:
	bundle install
	ruby server/currency_server.rb

# Run the Ruby gRPC client
client:
	bundle install
	ruby client/currency_client.rb
