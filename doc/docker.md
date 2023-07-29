# Docker

Docker is **not** supported by the human-essentials team. See more details in
the [Arch Decision doc][decision]. The [Dockerfile][dockerfile] and [docker
compose][compose] files in this repository are provided as a starting point for
engineers who'd like to use Docker in their own environments.

## Setup

Once docker is installed, run the following commands to setup the application.

1. Build the application image.

   ```bash
   docker compose build app
   ```

1. Set up the application and database.

   ```bash
   docker compose run --rm app bin/setup
   ```

## Rails Server and Console

You can start the application using the follow command, then access it via
[localhost:3000][localhost].

```bash
docker compose up -d
```

You can access the rails console using the following:

```bash
docker compose run --rm app bin/rails console
```

## Tests

You can run individual tests within the container by running the following:

```bash
docker compose run --rm app bundle exec rspec <test filepath>
```

_Note: Not all tests will run inside of docker. System tests in particular
should not be expected to run properly._

## Updates

Run the following to update application dependencies:

```bash
docker compose run --rm app bin/update
```

[compose]: ../docker-compose.yml
[decision]: architecture/decisions/0010-docker.md
[dockerfile]: ../Dockerfile
[localhost]: http://localhost:3000
