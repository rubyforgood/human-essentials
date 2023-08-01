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

System tests require a browser, which is not available in the app image. You
can start the included chrome container by running the following:

```bash
docker compose --profile chrome up -d
```

With the container running you can now run all tests:

```bash
docker compose run --rm app bin/rails spec
```

You can also run a subset of tests or a single test:

```bash
docker compose run --rm app bin/rails spec:<test type>
docker compose run --rm app bin/rspec <test filepath>
```

To stop (or terminate) the chrome container after running the tests, use:

```bash
docker compose --profile chrome [stop|down] chrome
```

_Note: The chrome container is only required for running system tests._

### Using the chrome container for local system tests

Additionally, you can run system tests locally against the chrome container.
To do so, you will need to set the following environment variables (also found
in [`.env.example`][.env]):

```dotenv
APP_HOST=host.docker.internal
SELENIUM_HOST=localhost
SELENIUM_PORT=4444
SELENIUM_REMOTE=1
```

With the variables set, execute the following to launch a container and run the
tests:

```bash
docker compose --profile chrome up
bundle exec rails spec:system
docker compose --profile chrome down chrome
```

## Updates

Run the following to update application dependencies:

```bash
docker compose run --rm app bin/update
```

[.env]: ../.env.example
[compose]: ../docker-compose.yml
[decision]: architecture/decisions/0010-docker.md
[dockerfile]: ../Dockerfile
[localhost]: http://localhost:3000
