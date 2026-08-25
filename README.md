# Spendout

Spendout is a free, source-available, self-hosted budgeting application. It keeps currency-specific sources, spending plans, expenses, and exchanges together without rewriting historical amounts or exchange quotes.

## Install with ONCE

Spendout is packaged as a single Docker image for [ONCE](https://github.com/basecamp/once). ONCE manages HTTPS, updates, persistent storage, and backups.

You need:

- A Linux or macOS machine supported by ONCE
- A hostname whose DNS points to that machine
- Ports 80 and 443 available
- SMTP credentials if users will sign in with emailed codes

Install ONCE on the machine:

```sh
curl https://get.once.com | sh
```

Deploy Spendout:

```sh
once deploy ghcr.io/spacepolice10/spendout:latest --host spendout.example.com
```

Open the hostname and create the first administrator with an email address and a password of at least 12 characters. Public registration is closed after setup. The administrator can add users with either a password or an emailed sign-in code.

Configure SMTP from the application's Email Settings screen in ONCE before adding code-only users. Spendout consumes ONCE's `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, and `MAILER_FROM_ADDRESS` variables directly.

## Persistent data and backups

Spendout keeps all persistent state under `/rails/storage`, which ONCE mounts to its managed application volume. This includes the primary SQLite database, Solid Cache, Solid Queue, Solid Cable, and local file uploads.

The image provides ONCE backup and restore hooks. They use SQLite's online backup operation to snapshot every production database without pausing the application. Restores replace the live databases with those consistent snapshots before Spendout boots.

## Run with Docker

For a local HTTP installation:

```sh
docker run --name spendout \
  --publish 3000:80 \
  --restart unless-stopped \
  --volume spendout_storage:/rails/storage \
  --env SECRET_KEY_BASE="$(openssl rand -hex 64)" \
  --env DISABLE_SSL=true \
  ghcr.io/spacepolice10/spendout:latest
```

Open `http://localhost:3000` and create the first administrator. Add SMTP environment variables to enable emailed codes.

## Development

Spendout requires Ruby 3.4.9 and SQLite.

```sh
bin/setup
bin/dev
```

Run the checks with:

```sh
bin/ci
```

Kamal maintainers can copy `config/deploy.yml.example` to the ignored `config/deploy.yml`, then copy `.kamal/secrets.example` to the ignored `.kamal/secrets`.

## Releasing

Push a semantic version tag to build and publish `linux/amd64` and `linux/arm64` images:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The release workflow publishes `1.0.0`, `1.0`, `1`, and `latest` tags to GitHub Container Registry. Prerelease versions do not update `latest`.

After the first release, set the `spendout` package visibility to **Public** in the GitHub repository's package settings so ONCE users can pull the image without GitHub credentials.

## License

Spendout uses the [O'Saasy License](LICENSE.md): self-hosting, modification, and redistribution are permitted, while offering Spendout itself as a competing hosted service is reserved to the copyright holder. The canonical license wording is published at [osaasy.dev](https://osaasy.dev/).
