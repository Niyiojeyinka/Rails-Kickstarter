# Contributing to Kickstart

Thanks for helping make Kickstart a better starting point! This project is a
Rails starter kit — contributions that make the *foundation* better (not
one-off domain features) are the most valuable.

## Getting started

```sh
cp .env.sample .env   # optional
bin/setup
bin/dev               # http://localhost:3000
```

You'll need Ruby 3.4.2 (`.ruby-version`), Node + Yarn, and Docker with
Postgres on `127.0.0.1:5432`. See the README for details and the dockerized
alternatives.

## Before submitting

```sh
bin/rails test           # or COVERAGE=1 bin/rails test (must stay ≥ 85%)
bin/rubocop
bin/brakeman
bin/bundler-audit
```

Keep the coverage floor honest — if your change adds logic, add tests for it.
Tests use Minitest with fixtures, [FactoryBot](https://github.com/thoughtbot/factory_bot)
factories (`test/factories.rb`), and [Mocha](https://github.com/freerange/mocha)
for stubbing.

## Pull requests

- Open an issue first for anything more than a small fix, so the direction
  can be discussed before you invest time.
- One logical change per PR, with a clear description of what and why.
- Follow the existing code style (Omakase Rubocop config — CI enforces it).
- Generate/refresh schema annotations with `bundle exec annotaterb models`.

## Code of conduct

All interactions follow the [Code of Conduct](CODE_OF_CONDUCT.md).
