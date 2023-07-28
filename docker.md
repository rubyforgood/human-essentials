# Docker
Docker is **not** supported by the human-essentials team. See more details in the [Arch Decision doc](/doc/architecture/decisions/0010-docker.md). The dockerfile and docker-compose in this repository is provided as a starting point for engineers who'd like to support Docker in their own environments.

## Setup
Once docker is installed, run the following commands to setup the application.

This will build the base image used by other containers.
```
docker-compose build app
```

This will setup the application and databases.
```
docker-compose run --rm app bin/setup
```

## Rails Server and Console
Run the application and access the server at [localhost:3000](localhost:3000).
```
docker-compose up
```

Access the rails console.
```
docker-compose run --rm app bin/rails c
```

## Tests
Run all tests.
```
docker-compose run --rm app bundle exec rspec
```

Run an individual test.
```
docker-compose run --rm app bundle exec rspec <test filepath>
```

## Updates
Update the dependencies on human-essentials.
```
docker-compose run --rm app bin/update
```