# ⚡ Kickstart — the Rails starter kit

A batteries-included **Rails 8.1** starter: clone it, and your next web
project already has an admin panel, authentication, feature flags, a GraphQL
API, observability, CI, and tests with coverage — wired and documented.

<!-- Update these badge URLs after publishing to GitHub:
![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)
-->
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Ruby 3.4](https://img.shields.io/badge/Ruby-3.4-red)
![Rails 8.1](https://img.shields.io/badge/Rails-8.1-cc0000)

## What's inside

| Area | Stack |
|---|---|
| **Framework** | Rails 8.1 · Ruby 3.4 · PostgreSQL · Propshaft + importmap · Turbo/Stimulus |
| **Admin** | [ActiveAdmin 4](https://activeadmin.info) + Devise — ops dashboard, admin users, feature-flag management at `/admin` |
| **Auth** | User auth (bcrypt) with **JWT sessions**, platform-admin sessions with opaque hashed tokens — both DB-tracked, revocable, with a sample JSON API |
| **GraphQL** | `/graphql` endpoint + GraphiQL IDE at `/graphiql` (development) |
| **Feature flags** | [Flipper](https://www.flippercloud.io/flipper) — declare a flag once, get generated helpers, manage it in the admin panel |
| **Background & cache** | Solid Queue / Solid Cache / Solid Cable — no Redis required |
| **Observability** | OpenTelemetry traces → Jaeger · Yabeda metrics → Prometheus · logs → Loki · all in Grafana, via one compose file |
| **Testing** | Minitest + FactoryBot + Faker + Mocha · SimpleCov (85% floor, Cobertura for CI) · system tests |
| **Quality** | RuboCop (Omakase) · Brakeman · bundler-audit · Bullet · annotaterb · letter_opener · rack-mini-profiler |
| **Deploy** | Production Dockerfile (Thruster) + docker-compose for production and dockerized development |

## Requirements

- Ruby 3.4.2 (see `.ruby-version`)
- Node.js + Yarn (Tailwind CSS build)
- Docker with Postgres on `127.0.0.1:5432` (`postgres` / `postgres` — override via `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`)

## 🚀 Quick start

```sh
git clone https://github.com/OWNER/REPO.git   # update OWNER/REPO
cd REPO
cp .env.sample .env    # optional — documented defaults for every env var
bin/setup              # bundle + yarn + create/migrate DB + seed
bin/dev                # http://localhost:3000
```

- **Admin**: http://localhost:3000/admin — `admin@example.com` / `password` (dev seed)
- **GraphiQL**: http://localhost:3000/graphiql
- **API**: `POST /api/v1/sign_up`, `/sign_in`, `/me`, `/sign_out` (see below)

Prefer containers?

```sh
docker compose -f docker-compose.dev.yml up --build   # dockerized development
# or the production stack:
KICKSTART_DATABASE_PASSWORD=… RAILS_MASTER_KEY=$(cat config/master.key) docker compose up -d --build
```

## Documentation

- **[docs/OBSERVABILITY.md](docs/OBSERVABILITY.md)** — step-by-step setup for tracing, metrics, and logs (Jaeger, Prometheus, Loki, Grafana), plus production notes

## Architecture in brief

### Components (business logic)

Business logic lives in `app/components/`, grouped by domain, following the
**Creator / Updater / Deleter** pattern:

```ruby
result = Users::Creator.call(email: "a@b.c", password: "s3cret")
result.success?  # => true
result.value     # => the created User
result.errors    # => ["Email is invalid"] on failure
```

See [app/components/application_component.rb](app/components/application_component.rb) and the
working examples (`AdminUsers::*`, `AdminSessions::*`, `UserSessions::*`,
`FeatureFlags::Toggler`).

### Feature flags

Declare a flag **once** in [config/flags.rb](config/flags.rb) — it generates
the helpers, shows up in the admin panel with its description, and caches in
Rails.cache:

```ruby
FeatureFlag.define(:new_checkout, description: "New checkout flow")

FeatureFlag.new_checkout_enabled?            # globally?
FeatureFlag.new_checkout_enabled?(user)      # for this actor?
FeatureFlag.enable_new_checkout              # enable/disable
FeatureFlag.enable_for(:new_checkout, user)  # any model / segment / percentage
```

### Authentication

```
User flow:      POST /api/v1/sign_up → sign_in (JWT) → me → sign_out (instant revoke)
Admin flow:     POST /api/v1/admin_sessions (opaque token, shown once) → validate → revoke
```

## Development & testing

```sh
bin/rails test            # full suite
COVERAGE=1 bin/rails test # coverage (HTML + cobertura.xml; ≥ 85% enforced)
bin/rubocop               # style
bin/brakeman              # static security analysis
```

Tests use Minitest with fixtures, [FactoryBot](https://github.com/thoughtbot/factory_bot)
factories ([test/factories.rb](test/factories.rb)), and [Mocha](https://github.com/freerange/mocha)
for stubbing.

## 🤝 Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
All interactions follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Please report vulnerabilities privately — see [SECURITY.md](SECURITY.md).

## License

Released under the [MIT License](LICENSE).

---

**Acknowledgements** — built on Rails, ActiveAdmin, Devise, Flipper,
GraphQL-Ruby, OpenTelemetry, Prometheus, Grafana, Loki, and the wider Ruby
ecosystem.
