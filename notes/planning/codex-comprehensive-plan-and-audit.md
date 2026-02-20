# Codex Comprehensive Plan and Codebase Audit

Date: 2026-02-18
Scope audited: `/Users/Pascal/code/unified/unified-ui`

## Executive Summary

The codebase is significantly ahead of the original planning checklists in Phases 2-4.
Core DSL entities, adapters for terminal/desktop/web, event modules, table/data-viz/navigation widgets, and a large test suite are already present.

The main remaining work is not basic scaffolding. It is completion and hardening:
- finish missing architecture pieces (Jido agent integration, dynamic signal/state generation)
- close feature gaps in Phase 4 (dialogs, advanced inputs, containers)
- production readiness work in Phase 5 (CI coverage gates, docs/guides, mix tasks, performance)

## Verification Method

- Static code audit of modules and tests.
- Initial audit run did not include runtime verification because `mix` was unavailable in that environment.

## Progress Update (2026-02-20)

- Track C.1 complete: adapter `update/3` paths are now diff-aware and skip no-op updates.
- Track C.2 complete: coordinator now supports platform event normalization and explicit target routing contracts.
- Track C.3 in progress: planning/architecture docs are being updated to consistently use `adapters/*` naming.

## Audit Findings by Phase

### Phase 1 (Foundation) - Mostly complete

Completed evidence:
- Dependencies include Spark/Jido/JidoSignal/TermUi and extracted `unified_iur` package (`mix.exs` lines 28-32).
- DSL extension is defined with sections, transformers, and verifiers (`lib/unified_ui/dsl/extension.ex` lines 267-274).
- Signal helpers are implemented (`lib/unified_ui/signals.ex` lines 69-213).
- Elm behavior and base transformers exist (`lib/unified_ui/elm_architecture.ex`; `lib/unified_ui/dsl/transformers/*.ex`).

Gaps:
- Jido agent integration module/helpers from plan are not implemented (no `UnifiedUi.Agent` module found).
- Application supervision tree is still a placeholder (`lib/unified_ui/application.ex` lines 10-12).
- Legacy section modules remain as "future phase" placeholders and are likely stale relative to `extension.ex` (`lib/unified_ui/dsl/sections/widgets.ex` line 44, `lib/unified_ui/dsl/sections/layouts.ex` line 45, `lib/unified_ui/dsl/sections/styles.ex` line 95, `lib/unified_ui/dsl/sections/signals.ex` line 76).

### Phase 2 (Core Widgets and Layouts) - Substantially complete

Completed evidence:
- Core widget entities (`button`, `text`, `label`, `text_input`) implemented (`lib/unified_ui/dsl/entities/widgets.ex` lines 239-248).
- Core layout entities (`vbox`, `hbox`) implemented (`lib/unified_ui/dsl/entities/layouts.ex` lines 148-151).
- Form/state/style helpers implemented (`lib/unified_ui/dsl/form_helpers.ex` lines 109-459; `lib/unified_ui/dsl/state_helpers.ex` lines 49-136; `lib/unified_ui/dsl/style_resolver.ex` lines 87-269).
- IUR builder exists (`lib/unified_ui/iur/builder.ex` line 85 onward).
- Verifiers exist for unique IDs/layout/signal/style/state (`lib/unified_ui/dsl/verifiers.ex`).

Gaps:
- `UpdateTransformer` still documents future signal extraction, currently generated handlers are generic (`lib/unified_ui/dsl/transformers/update_transformer.ex` lines 13 and 49).
- State-reference verifier still marks interpolation verification as placeholder (`lib/unified_ui/dsl/verifiers.ex` line 383).
- IUR builder dispatch currently handles navigation/basic widgets/layouts but does not dispatch data-viz/table entities from DSL (`lib/unified_ui/iur/builder.ex` lines 112-152).

### Phase 3 (Renderer Implementations) - Substantially complete

Completed evidence:
- Shared renderer behavior callbacks (`lib/unified_ui/adapters/protocol.ex` lines 1, 116, 150, 173).
- Shared traversal/find/style utilities (`lib/unified_ui/adapters/shared.ex` lines 82, 113, 172, 299).
- Terminal/Desktop/Web adapters implement behavior (`lib/unified_ui/adapters/terminal/renderer.ex` lines 49, 58, 71, 78; `lib/unified_ui/adapters/desktop/renderer.ex` lines 60, 69, 82, 89; `lib/unified_ui/adapters/web/renderer.ex` lines 56, 65, 78, 85).
- Terminal/Desktop/Web event modules implemented (`lib/unified_ui/adapters/terminal/events.ex` lines 77, 124; `lib/unified_ui/adapters/desktop/events.ex` lines 104, 156; `lib/unified_ui/adapters/web/events.ex` lines 104, 156).
- Multi-platform coordinator implemented (`lib/unified_ui/adapters/coordinator.ex`).

Gaps:
- Update paths still perform root-level recompute; subtree-level incremental patching by element ID is not implemented yet.
- Event routing now exists at the coordinator level, but agent/supervision integration is still pending.
- Naming diverged from original plan (`adapters/*` vs `renderers/*`), which is fine technically but planning docs should be aligned.

### Phase 4 (Advanced Features and Styling) - Partial completion

Completed evidence:
- Data-viz entities exist (`lib/unified_ui/dsl/entities/data_viz.ex` lines 349-355).
- Table entities and sorting logic exist (`lib/unified_ui/dsl/entities/tables.ex` lines 252-254; `lib/unified_ui/table/sort.ex`).
- Navigation entities exist (`lib/unified_ui/dsl/entities/navigation.ex` lines 586-591).
- Render support for data-viz/table/navigation exists in all three adapters (terminal/desktop/web renderer modules).

Gaps:
- No implementation found for dialog/alert/toast, pick_list/form_builder, viewport/split_pane, and other remaining advanced widgets from plan.

### Phase 5 (Testing, Docs, Tooling) - Early/partial

Completed evidence:
- Broad test surface exists, including phase integration tests:
  - `test/unified_ui/integration/phase_2_test.exs`
  - `test/unified_ui/integration/phase_3_test.exs`
  - `test/unified_ui/integration/phase_4_test.exs`
- Adapter, entity, transformer tests are present under `test/unified_ui/adapters`, `test/unified_ui/dsl/entities`, `test/unified_ui/dsl/transformers`.

Gaps:
- No evidence of coverage gate/coverage tooling in project config.
- No mix task modules for `mix unified_ui.*` found.
- `mix.exs` docs config points to non-existent guides (`mix.exs` lines 58-59, no `guides/` directory found).
- Root README still has placeholder text (`README.md` line 3).

## Comprehensive Delivery Plan (Rebased on Current Reality)

### Track A - Foundation Hardening (highest priority)

1. Implement runtime integration for components as agents.
- Add `UnifiedUi.Agent` API and Jido agent lifecycle hooks.
- Add registry/supervisor children in `UnifiedUi.Application`.
- Exit criteria: components can be started/stopped and receive routed signals end-to-end.

2. Complete transformer maturity.
- Update `UpdateTransformer` to derive handler clauses from DSL entities instead of generic fallbacks.
- Complete state interpolation/state reference validation pipeline.
- Exit criteria: DSL declarations directly drive generated `update/2` and consistent state wiring.

3. Remove/align stale DSL section modules.
- Either delete unused placeholder section modules or wire them as authoritative sources.
- Exit criteria: one canonical DSL definition path; no "future phase" placeholders contradicting implementation.

### Track B - DSL-to-IUR Completeness

1. Extend `UnifiedUi.IUR.Builder` for all existing DSL entities.
- Add `gauge/sparkline/bar_chart/line_chart/table` builder dispatch and constructors.
- Add regression tests for full DSL -> IUR conversion, not only direct IUR struct tests.
- Exit criteria: every entity in `extension.ex` is buildable from DSL state.

2. Validate full build path with complex nested examples.
- Add integration tests that define modules with the DSL and assert resulting IUR shape.
- Exit criteria: one golden example per major widget family.

### Track C - Renderer Runtime Hardening

1. Move from rerender to diff-aware update.
- Add element-ID matching and incremental update logic where possible.
- Exit criteria: `update/3` applies structural diff, no full rerender default for unchanged subtrees.
Status: complete for root-level diff-aware updates; subtree-level incremental patching remains.

2. Strengthen event dispatch path.
- Complete bus dispatch wiring and target routing contracts.
- Exit criteria: platform event -> normalized signal -> target handler integration tests pass.
Status: complete for coordinator normalization/routing contracts; bus/agent integration remains.

3. Align naming and architecture docs.
- Update planning docs from "renderers" to actual "adapters" naming or rename code consistently.
- Exit criteria: docs and code terminology match.
Status: in progress.

### Track D - Finish Remaining Phase 4 Features

1. Implement missing advanced widgets and render support.
- Dialog/alert/toast.
- Pick list/form builder.
- Viewport/split pane.
- Exit criteria: entity + IUR + terminal/desktop/web render + events + tests for each widget family.

2. Add accessibility and keyboard contracts where relevant (web/desktop especially).
- Exit criteria: documented keyboard interactions and event parity tests.

### Track E - Production Readiness (Phase 5)

1. Test execution and CI gates.
- Add CI job with `mix test`, coverage reporting, and threshold gate.
- Exit criteria: reproducible CI pass and stated coverage target.

2. Documentation and guides.
- Fix missing `guides/` references or create the files.
- Add API docs configuration dependencies and generate docs in CI.
- Replace placeholder root README content.
- Exit criteria: docs build cleanly and published artifact path is defined.

3. Developer tooling.
- Add `mix unified_ui.*` tasks planned for scaffolding/generation/preview.
- Exit criteria: tasks available via `mix help` and covered by tests.

4. Performance and benchmark baseline.
- Add benchmark scripts and baseline targets.
- Exit criteria: measurable baseline committed and tracked.

## Recommended Execution Order

1. Track A (Foundation Hardening)
2. Track B (DSL-to-IUR Completeness)
3. Track C (Renderer Runtime Hardening)
4. Track D (Remaining Phase 4 Features)
5. Track E (Production Readiness)

Rationale: Tracks A/B/C reduce architecture risk and rework before adding more widget surface area; Track E should finalize once behavior is stable.
