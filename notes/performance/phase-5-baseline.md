# Phase 5 Baseline Profiling

This document captures the baseline benchmark suite introduced for Phase 5 performance optimization.

## Scope

The benchmark script profiles:

- DSL compilation time for a generated screen with 100 widgets
- IUR generation for a large UI tree
- Concurrent rendering across terminal, desktop, and web adapters
- Signal dispatch roundtrip latency (dispatch + state readback)
- Style resolution performance with deep inheritance

## How To Run

- Full run: `mix unified_ui.bench`
- CI quick run: `mix unified_ui.bench --quick`
- CI budget check: `mix unified_ui.perf.check --quick`

The CI workflow executes the quick run in the `benchmark` job.

## Baseline Notes

Use this file to track how benchmark throughput changes over time and to spot regressions before optimization work is merged.

Sample quick-run baseline (Apple M4, Elixir 1.19.5, Erlang 28.3.1):

- DSL compile profile (100 widgets): `1476.26 ms`
- `iur.build.large_ui`: `~0.77 K ips` (`~1301.32 us`)
- `render.concurrent.all_platforms`: `~2.26 K ips` (`~441.80 us`)
- `signals.dispatch.roundtrip`: `~892.83 K ips` (`~1.12 us`)
- `style.resolve.deep_inheritance`: `~76.74 K ips` (`~13.03 us`)
