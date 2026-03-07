# Phase 5 Bottlenecks And Targets

Last updated: March 7, 2026

This document summarizes the top performance bottlenecks identified from the
Phase 5 baseline profiling and defines concrete targets/budgets for ongoing
optimization and regression detection.

## Top 5 Bottlenecks

Based on `mix unified_ui.bench --quick` baseline measurements:

1. DSL compilation for 100 widgets is high (`~1476 ms`), far above the desired `<100 ms` target.
2. Large IUR tree generation is the slowest steady-state runtime path (`~1301 us` average in quick mode).
3. Concurrent multi-platform rendering has moderate per-call latency (`~442 us` average) and compounds with render frequency.
4. Style resolution with deep inheritance allocates heavily (`~44.85 KB` per run in baseline), making repeated resolution expensive.
5. IUR build path has high allocation pressure (`~3289 KB` measured in baseline memory stats), limiting scalability under load.

## Targets

### Product Targets (Phase 5 goals)

- DSL compilation: `<100 ms` for a 100-widget screen
- Terminal frame budget: `<=16.67 ms` per frame (60 FPS)

### Regression Budgets (CI guardrails)

These are current guardrails used by `mix unified_ui.perf.check --quick` to
catch major regressions while optimization work is still in progress:

- `dsl.compile.100_widgets`: `<=3500 ms`
- `iur.build.large_ui.avg`: `<=2500 us`
- `render.concurrent.all_platforms.avg`: `<=1200 us`
- `signals.dispatch.roundtrip.avg`: `<=20 us`
- `style.resolve.deep_inheritance.avg`: `<=40 us`

The regression budgets are intentionally looser than product targets; they
protect baseline stability while we iterate on optimization tasks 5.2.7-5.2.9.

## CI Enforcement

- `mix unified_ui.bench --quick` records comparative benchmark metrics.
- `mix unified_ui.perf.check --quick` enforces budget thresholds and fails CI on regression.
