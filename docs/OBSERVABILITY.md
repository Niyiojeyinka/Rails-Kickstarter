# Observability: OpenTelemetry + Prometheus + Grafana

This guide covers the full local setup for tracing, metrics, and logs — from
zero to seeing requests, dashboards, and log lines in Jaeger, Prometheus,
Loki, and Grafana — plus production notes.

## 1. Architecture

```
                        ┌──────────────────────────────────────────────┐
                        │              Rails app (host)                │
                        │                                              │
                        │  OpenTelemetry SDK ──OTLP HTTP──┐            │
                        │  (traces, every request)        │            │
                        │  Yabeda /metrics :9394 ◄────────┼───┐        │
                        │  log/*.log ──► Promtail ──► Loki │   │        │
                        └───────────────────────────────┬─┴────┼───────┘
                                                         ▼      │
                    ┌────────────────────────┐                  │
                    │  otel-collector :4318  │                  │
                    │  batches + forwards    │                  │
                    └───────────┬────────────┘                  │
                                │ OTLP gRPC                   │
                                ▼                               │
                    ┌────────────────────────┐                  │
                    │  Jaeger all-in-one     │                  │
                    │  UI :16686             │                  │
                    └────────────────────────┘                  │
                                                                 │ Prometheus scrape
  ┌──────────────────────────────┐                               ▼
  │  Grafana :3001               │◄──────────────┐   ┌────────────────────────┐
  │  dashboards + explore        │  queries      │   │  Prometheus :9090      │
  │  datasources: prom, jaeger,  │───────────────┘   │  scrapes app + coll.   │
  │               loki           │                   └────────────────────────┘
  └──────────────────────────────┘
```

* **Traces**: Rails app → OpenTelemetry SDK → OTLP HTTP → OpenTelemetry
  Collector → Jaeger. Every request, DB query, and HTTP call becomes a span.
* **Metrics**: Rails app exposes Prometheus metrics via Yabeda on port
  `9394/metrics`; Prometheus scrapes the app and the collector; Grafana
  queries Prometheus and renders dashboards.
* **Logs**: Promtail tails the Rails log files (`log/*.log`, mounted from the
  host) and pushes them to Loki; Grafana queries Loki for log browsing.
* **The app runs on the host**; the stack runs in Docker. Containers reach the
  app through `host.docker.internal`.

## 2. Prerequisites

- Docker (with Docker Compose) — already used for Postgres/Redis locally
- The app dependencies installed (`bundle install` done by `bin/setup`)
- Ruby 3.4.2 (`.ruby-version`)

No API keys, agents, or accounts are required for the local stack.

## 3. Step-by-step setup

### Step 3.1 — Start the observability stack

```sh
cd kickstart
docker compose -f docker-compose.observability.yml up -d
```

This starts four containers:

| Service | Purpose | Where |
|---|---|---|
| otel-collector | receives OTLP traces from the app, forwards to Jaeger | :4317 (gRPC), :4318 (HTTP), :8889 (own metrics) |
| jaeger | trace storage + search UI | http://localhost:16686 |
| prometheus | scrapes app :9394 + collector :8889 | http://localhost:9090 |
| loki | log aggregation, fed by Promtail | http://localhost:3100 |
| promtail | tails the app's `log/*.log` into Loki | — |
| grafana | dashboards (admin / admin) | http://localhost:3001 |

Verify they're up:

```sh
docker compose -f docker-compose.observability.yml ps
```

All six should show `Up`/`running`. Check the collector's own metrics as a
sanity check: `curl http://localhost:8889/metrics | head`.

### Step 3.2 — Run the app with tracing enabled

The OpenTelemetry SDK only exports when an OTLP endpoint is configured
(`config/initializers/opentelemetry.rb`), so plain `bin/dev` stays quiet.
Point it at the local collector:

```sh
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 bin/dev
```

(Or `bin/rails server` — same thing. `bin/dev` also runs the Tailwind watch
process.)

The metrics server starts automatically with the app on port 9394, bound to
loopback and protected with HTTP Basic auth. Confirm (credentials default to
`prometheus` / `dev-metrics-password`, see the configuration reference):

```sh
curl -u prometheus:dev-metrics-password http://localhost:9394/metrics
```

You should see Yabeda/Puma metric families such as
`rails_requests_total`, `rails_request_duration_seconds_bucket`,
`puma_busy_threads`, `puma_pool_capacity`.

### Step 3.3 — Generate some traffic

```sh
# A few requests with interesting internals:
curl http://localhost:3000/up
curl http://localhost:3000/flipper
curl http://localhost:3000/admin/login
curl http://localhost:3000/up && curl http://localhost:3000/up
```

Every request (including DB queries inside it) produces a trace.

### Step 3.4 — See traces in Jaeger

1. Open http://localhost:16686
2. In the **Service** dropdown pick `kickstart`
3. Click **Find Traces** — you'll see recent requests
4. Click a trace to expand its spans: Rack request → Rails action →
   ActiveRecord / pg spans with timing
5. The **System Architecture** and **Compare Traces** tabs are handy once
   there's more volume.

### Step 3.5 — See metrics in Prometheus

Open http://localhost:9090 → **Graph** → run any of:

```promql
sum(rate(rails_requests_total[5m])) by (controller)          # req/s by controller
histogram_quantile(0.95, sum(rate(rails_request_duration_seconds_bucket[5m])) by (le))  # p95 latency
puma_busy_threads                                             # thread pool usage
```

Under **Status → Targets** both jobs should be `UP`:
`rails-app` (`host.docker.internal:9394`) and `otel-collector`.

### Step 3.6 — See logs in Grafana

Promtail tails the Rails log files (`log/development.log`, `log/production.log`
…) and pushes them to Loki:

1. Open Grafana (http://localhost:3001) → **Explore** → pick the **Loki**
   datasource in the top dropdown.
2. Run the query `{job="rails"}` — you'll see the app's log lines live.
3. Useful refinements:
   - `{job="rails"} |= "ERROR"` — errors only (Loki also auto-labels
     `detected_level` per line, e.g. `{job="rails", detected_level="error"}`)
   - `{job="rails"} |= "ActiveAdmin"` — full-text filter
   - `{filename="/logs/development.log"}` — a single log file
4. The provisioned **Kickstart Rails Overview** dashboard also has an
   *Application logs* panel at the bottom.

### Step 3.7 — See dashboards in Grafana

1. Open http://localhost:3001 — login `admin` / `admin` (change it for anything long-lived)
2. **Dashboards → Kickstart Rails Overview** is provisioned automatically:
   request rate by controller, p95 request duration, status codes, DB time,
   Puma threads, and an application logs panel.
3. To dig into a spike: click a panel → **Explore** → the query is loaded in
   Prometheus; adjust the time range with the top-right picker.

### Step 3.8 — Add your own dashboard

1. In Grafana: **Dashboards → New → New dashboard → Add visualization**
2. Pick the **Prometheus** datasource, paste a PromQL query (see 3.5)
3. Save the dashboard; to keep it in the repo, export the JSON
   (**Share → Export → Save to file**) into `config/grafana/dashboards/` —
   the provisioning provider reloads every 30 s and picks up new files
   automatically (restart Grafana if it doesn't show).

### Step 3.9 — Stop the stack

```sh
docker compose -f docker-compose.observability.yml down
```

No state is persisted (dev stack). Bring it back any time with `up -d`.

## 4. Configuration reference

| Env var | Default | Meaning |
|---|---|---|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | *(unset — no export in dev)* | OTLP endpoint, e.g. `http://localhost:4318` or `https://otlp.example.com` |
| `OTEL_SERVICE_NAME` | `kickstart` | Service name in traces |
| `OTEL_TRACES_SAMPLER` | SDK default | `always_on`, `parentbased_traceidratio`, … |
| `OTEL_TRACES_SAMPLER_ARG` | SDK default | Ratio for traceidratio samplers (0.0–1.0) |
| `METRICS_PORT` | `9394` | Port for the Yabeda Prometheus endpoint (`:port/metrics`) |
| `METRICS_AUTH_USERNAME` | `prometheus` | Basic-auth username for the metrics endpoint |
| `METRICS_AUTH_PASSWORD` | `dev-metrics-password` | Basic-auth password for the metrics endpoint |
| `APP_VERSION` | *(unset)* | Tagged onto spans as `service.version` |

Any other `OTEL_*` variable the OpenTelemetry SDK understands also works —
these are just the ones this app reads explicitly.

## 5. Production notes

- **Collector placement**: run an OTel Collector (or a vendor's OTLP gateway)
  close to the app; the app only ever sends OTLP to `OTEL_EXPORTER_OTLP_ENDPOINT`.
  The local Jaeger/Prometheus/Grafana trio in `docker-compose.observability.yml`
  is for development only.
- **Sampling**: at high traffic, set
  `OTEL_TRACES_SAMPLER=parentbased_traceidratio` and `OTEL_TRACES_SAMPLER_ARG=0.1`
  (10%) and adjust to keep trace volume (and cost) in check.
- **Batch + timeouts**: the SDK batches spans (default 5 s / 512 spans) and
  retries, so a briefly unavailable collector does not fail requests.
- **Metrics vs traces**: metrics come from Yabeda on `:9394/metrics` (scrape
  that with your production Prometheus); traces flow through OTLP. They're
  independent — losing the collector never affects metrics.
- **Metrics endpoint security**: the endpoint is loopback-bound with HTTP
  Basic auth. In production, rotate `METRICS_AUTH_PASSWORD` (and keep
  Prometheus' `basic_auth` in sync), and prefer scraping over a private
  network or TLS — basic auth alone is cleartext.
- **Stack UIs**: Jaeger/Prometheus/Loki/Grafana container ports are published
  loopback-only in `docker-compose.observability.yml`. Grafana additionally
  requires login; add auth in front of Jaeger/Prometheus UIs before exposing
  them anywhere beyond localhost.
- **Logs**: in production, run Promtail (or Grafana Alloy) where your logs are
  written — it tails files or reads the Docker socket — and point it at your
  Loki. Consider structured logs (JSON) so Loki pipelines can extract fields;
  the Rails default tagged format already gives Promtail the level.
- **Health checks**: keep `/up` (built into Rails) wired into your load
  balancer; it's also a convenient canary trace.
- **Secrets**: never put credentials in `docker-compose.observability.yml`
  style files for production; use a secrets manager.

## 6. Troubleshooting

**No traces in Jaeger**
1. `curl http://localhost:8889/metrics | grep otelcol_exporter` — if empty, the collector didn't start; check `docker compose -f docker-compose.observability.yml logs otel-collector`
2. Is the app running with `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`? Without it, dev exports nothing (by design).
3. Look for span export errors in the Rails log (`Failed to export spans` / connection refused → collector down or wrong port).
4. Confirm the exporter is active from the console:
   `bin/rails runner 'puts OpenTelemetry.tracer_provider.active_span_processor.class'`

**Jaeger shows traces but no spans under them**
The collector debug exporter also prints spans to its own logs —
`docker compose -f docker-compose.observability.yml logs otel-collector` should
show trace data arriving; if empty, the app isn't reaching the collector.

**Prometheus target `rails-app` is DOWN**
1. Is the app running? The metrics server starts with it.
2. `curl -u prometheus:dev-metrics-password http://localhost:9394/metrics`
   from the host — works? A `401` means the credentials don't match: check
   `METRICS_AUTH_USERNAME` / `METRICS_AUTH_PASSWORD` (app side) against the
   `basic_auth` block in `config/prometheus/prometheus.yml`.
3. From inside the network:
   `docker compose -f docker-compose.observability.yml exec prometheus wget -qO- --header="Authorization: Basic $(echo -n prometheus:dev-metrics-password | base64)" http://host.docker.internal:9394/metrics | head`
   If that fails but step 2 works, the Docker version lacks host-gateway
   support — replace `host.docker.internal` with your LAN IP in
   `config/prometheus/prometheus.yml`.

**Grafana dashboard shows "No data"**
- Check **Connections → Data sources** — Prometheus must be listed and healthy.
- The metric names must appear in Prometheus first (Step 3.5); without app
  traffic, `rails_*` series don't exist yet.
- Time range: the dashboard defaults to the last 15 minutes.

**No logs in Grafana / Loki**
1. `docker compose -f docker-compose.observability.yml logs promtail` — it
   should show files discovered in `/logs`; if it can't read them, the app's
   log files may not exist yet (generate traffic) or permissions may block the
   read-only mount.
2. `curl http://localhost:3100/ready` → should answer `ready`.
3. In Grafana, check the **Loki** datasource under **Connections → Data
   sources** — "Save & test" should succeed.
4. Promtail remembers its position in `/tmp/positions.yaml` *inside the
   container*, so old lines are only picked up after a restart if you reset
   positions (`docker compose -f docker-compose.observability.yml exec promtail
   rm /tmp/positions.yaml`).

**Port conflicts**
The stack binds 3000/9394 on the host app and
16686/9090/3001/3100/4317/4318/8889 in containers. If something else uses
these ports, remap the left-hand side of the `ports:` entries in
`docker-compose.observability.yml` and update `OTEL_EXPORTER_OTLP_ENDPOINT`
accordingly.
