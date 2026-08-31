# Spendout

Spendout is a self-hosted budgeting application for tracking currency-specific sources, spending plans, expenses, and exchanges without rewriting historical amounts or exchange quotes.

## Deployment options

The `main` branch is configured for a manual [Kamal](https://kamal-deploy.org/) deployment. ONCE packaging, first-run administrator setup, and the self-hosting release workflow are being developed on [`codex/once-adaptation`](https://github.com/spacepolice10/spendout/tree/codex/once-adaptation).

To inspect or test the ONCE version locally:

```sh
git fetch origin
git switch codex/once-adaptation
```

Return to the Kamal version with `git switch main`.

## Manual deployment with Kamal

You need:

- A Linux server reachable over SSH
- A domain name pointed at the server
- A Docker image registry such as Docker Hub or GitHub Container Registry
- Ruby and the project dependencies installed on the computer from which you deploy
- SMTP credentials for emailed authentication codes

Clone the repository and install its dependencies:

```sh
git clone https://github.com/spacepolice10/spendout.git
cd spendout
bin/setup
```

Create local deployment configuration from the safe examples:

```sh
cp config/deploy.yml.example config/deploy.yml
cp .kamal/secrets.example .kamal/secrets
```

Edit `config/deploy.yml` and replace every example value with your server address, hostname, registry account, SMTP server, and desired image name. If the target server is not `amd64`, also change `builder.arch`.

Provide the two required secrets in your shell or replace their lookups in `.kamal/secrets` with commands from your password manager:

```sh
export KAMAL_REGISTRY_PASSWORD="your-registry-token"
export RAILS_MASTER_KEY="the-content-of-config/master.key"
```

Both `config/deploy.yml` and `.kamal/secrets` are ignored by Git. Keep them local; do not commit either file.

Set up a new server and deploy the application:

```sh
bin/kamal setup
```

For later releases, deploy the current commit with:

```sh
bin/kamal deploy
```

Useful operational commands include:

```sh
bin/kamal app logs -f
bin/kamal console
bin/kamal shell
```

Application data is stored in the `spendout_storage` Docker volume mounted at `/rails/storage`. Back up that volume before server maintenance or destructive changes.

## Development

Spendout requires Ruby 3.4.10 and SQLite.

```sh
bin/setup
bin/dev
```

Run the test and style checks with:

```sh
bin/ci
```

## License

Spendout is available under the [O'Saasy License](LICENSE.md): MIT with the commercial right to run it as a competing hosted SaaS reserved for the copyright holder. See [osaasy.dev](https://osaasy.dev/).
