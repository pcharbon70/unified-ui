# Phase 1: Foundation

This phase establishes the foundational infrastructure for the UnifiedUi library. We create the project structure, set up the Spark DSL framework, design the Intermediate UI Representation (IUR), and establish the patterns that all subsequent phases will build upon.

---

## 1.1 Project Initialization

- [x] **Task 1.1** Create Elixir library structure with proper directory layout

Initialize the UnifiedUi library with the appropriate directory structure for DSL definitions, code generation, and platform-specific renderers.

- [x] 1.1.1 Create new Elixir library with `mix new unified_ui --sup`
- [x] 1.1.2 Configure application metadata in mix.exs (name, description, licenses)
- [x] 1.1.3 Create directory structure under lib/unified_ui:
  - `dsl/` - Spark DSL definitions
  - `widgets/` - Widget target structs
  - `layouts/` - Layout target structs
  - `styles/` - Style system
  - `iur/` - Intermediate UI Representation
  - `renderers/` - Platform-specific renderers
- [x] 1.1.4 Create mirror test directory structure
- [x] 1.1.5 Add required dependencies to mix.exs:
  - `{:spark, "~> 1.0"}` - DSL framework
  - `{:jido, "~> 1.0"}` - Agent system
  - `{:jido_signal, "~> 1.0"}` - Signal communication
  - `{:term_ui, github: "pcharbon70/term_ui", branch: "multi-renderer"}` - Terminal UI dependency
- [x] 1.1.6 Create `.formatter.exs` with `import_deps: [:spark]`
- [x] 1.1.7 Create config/config.exs with basic application configuration

**Implementation Notes:**
- Library (not application) structure since this will be used as a dependency
- `--sup` flag ensures we can start supervision trees if needed
- Directory structure follows Spark conventions for DSL organization
- **Note**: term_ui dependency uses `multi-renderer` branch due to compilation issue on main

**Unit Tests for Section 1.1:**
- [x] Test application compiles with `mix compile`
- [x] Test application starts with `mix test`
- [x] Verify all dependencies resolve with `mix deps.get`
- [x] Verify directory structure exists

---

## 1.2 Spark DSL Extension Module

- [ ] **Task 1.2** Create the core Spark DSL Extension module

Define the Spark.Dsl.Extension that aggregates all DSL entities, sections, transformers, and verifiers into a cohesive DSL.

- [ ] 1.2.1 Create `lib/unified_ui/dsl/extension.ex` with `use Spark.Dsl.Extension`
- [ ] 1.2.2 Define the `:ui` section as the top-level section for UI definitions
- [ ] 1.2.3 Define the `:widgets` section for widget entity definitions
- [ ] 1.2.4 Define the `:layouts` section for layout entity definitions
- [ ] 1.2.5 Define the `:styles` section for style and theme definitions
- [ ] 1.2.6 Define the `:signals` section for signal type definitions
- [ ] 1.2.7 Configure entity imports for all sections
- [ ] 1.2.8 Configure section imports for nested entities
- [ ] 1.2.9 Add `@moduledoc` with DSL usage examples
- [ ] 1.2.10 Configure `@doc false` for internal helper functions

**Implementation Notes:**
- Extension follows Spark pattern: `@section [` sections...]
- Each section has a `@entities` list with entity definitions
- Top-level `:ui` section serves as entry point for UI definitions

**Unit Tests for Section 1.2:**
- [ ] Test extension module compiles without errors
- [ ] Test all sections are properly registered
- [ ] Test section imports work correctly
- [ ] Test entity imports work correctly

---

## 1.3 Intermediate UI Representation Design

- [x] **Task 1.3** Design and implement the Intermediate UI Representation (IUR) system

Create a set of Elixir structs that represent UI elements in a platform-agnostic manner. The IUR is what the view/1 function returns and what renderers consume.

- [x] 1.3.1 Create `lib/unified_ui/iur/element.ex` with:
  - `UnifiedUi.IUR.Element` protocol
  - `children/1` function for tree traversal
  - `metadata/1` function for element properties
- [x] 1.3.2 Create `lib/unified_ui/iur/widgets.ex` with base widget structs:
  - `UnifiedUi.IUR.Widgets.Text` - content, style, id
  - `UnifiedUi.IUR.Widgets.Button` - label, on_click, disabled, style, id
- [x] 1.3.3 Create `lib/unified_ui/iur/layouts.ex` with base layout structs:
  - `UnifiedUi.IUR.Layouts.VBox` - children, spacing, align
  - `UnifiedUi.IUR.Layouts.HBox` - children, spacing, align
- [x] 1.3.4 Create `lib/unified_ui/iur/styles.ex` with:
  - `UnifiedUi.IUR.Style` - fg, bg, attrs, padding
  - Style attribute definitions
  - Style merge functions
- [x] 1.3.5 Implement `c:UnifiedUi.IUR.Element.children/1` for all structs
- [x] 1.3.6 Implement `c:UnifiedUi.IUR.Element.metadata/1` for all structs
- [x] 1.3.7 Add IUR validation helpers
- [x] 1.3.8 Document IUR contract for renderer implementers

**Implementation Notes:**
- IUR structs are simple data containers (no business logic)
- Protocol-based design allows extensibility
- Style struct uses platform-agnostic attribute names

**Unit Tests for Section 1.3:**
- [x] Test Text IUR struct creation
- [x] Test Button IUR struct creation
- [x] Test VBox IUR struct with children
- [x] Test HBox IUR struct with children
- [x] Test Style struct creation
- [x] Test Element.protocol children/1 works
- [x] Test Element.protocol metadata/1 extracts properties
- [x] Test style merge functions

---

## 1.4 Signal and Event Handling Constructs

- [x] **Task 1.4** Define signal helpers and event handling constructs

Create helper functions for working with Jido.Signal, enabling UI components to emit and respond to signal messages.

- [x] 1.4.1 Create `lib/unified_ui/signals.ex` helper module
- [x] 1.4.2 Define standard_signals/0 returning list of standard signal names
- [x] 1.4.3 Define signal_type/1 mapping atoms to type strings
- [x] 1.4.4 Define create/3 for creating Jido.Signal from atom or string
- [x] 1.4.5 Define create!/3 raising version for known-valid signals
- [x] 1.4.6 Define valid_type/1 for validating signal type format
- [x] 1.4.7 Define standard signal types:
  - `:click` - Button/element clicked
  - `:change` - Input value changed
  - `:submit` - Form submitted
  - `:focus` - Element gained focus
  - `:blur` - Element lost focus
  - `:select` - Item selected

**Implementation Notes:**
- Uses Jido.Signal directly (no intermediate wrapper struct)
- Helper functions in `UnifiedUi.Signals` for common UI signal types
- Standard signals provide baseline; custom signals created with `Jido.Signal.new/1`
- Signal type format: `"domain.entity.action"` (e.g., `"unified.button.clicked"`)

**Unit Tests for Section 1.4:**
- [x] Test standard_signals/0 returns list of signal names
- [x] Test signal_type/1 maps atoms to type strings
- [x] Test create/3 creates Jido.Signal from atom
- [x] Test create/3 creates Jido.Signal from custom type string
- [x] Test create!/3 raises on invalid signal name
- [x] Test valid_type/1 validates signal type format

---

## 1.5 Elm Architecture Transformers

- [ ] **Task 1.5** Implement Spark transformers that generate Elm Architecture boilerplate

Create transformers that automatically generate the `init/1`, `update/2`, and `view/1` functions required by The Elm Architecture.

- [ ] 1.5.1 Create `lib/unified_ui/dsl/transformers/elm_arch.ex`
- [ ] 1.5.2 Define `init_transformer` that:
  - Extracts initial state from DSL definitions
  - Generates `init/1` function with initial state map
- [ ] 1.5.3 Define `update_transformer` that:
  - Extracts signal handler definitions from DSL
  - Generates `update/2` function with pattern matching on signals
- [ ] 1.5.4 Define `view_transformer` that:
  - Traverses the DSL UI tree structure
  - Generates `view/1` function that returns IUR
- [ ] 1.5.5 Implement state interpolation for dynamic content
- [ ] 1.5.6 Add `@behaviour UnifiedUi.ElmArchitecture` to generated modules
- [ ] 1.5.7 Create `UnifiedUi.ElmArchitecture` behaviour definition

**Implementation Notes:**
- Transformers use `Spark.Dsl.Transformer` behaviour
- Each transformer implements `transform(dsl_state)` function
- State is a map with atom keys for type safety
- View function returns IUR structs

**Unit Tests for Section 1.5:**
- [ ] Test init_transformer generates init/1 function
- [ ] Test update_transformer generates update/2 function
- [ ] Test view_transformer generates view/1 function
- [ ] Test view returns IUR struct tree
- [ ] Test generated module adopts ElmArchitecture behaviour

---

## 1.6 Jido Agent Integration Transformers

- [ ] **Task 1.6** Implement Spark transformers for Jido.Agent.Server integration

Create transformers that automatically generate the boilerplate for integrating UI components as Jido.Agent.Server processes.

- [ ] 1.6.1 Create `lib/unified_ui/dsl/transformers/jido_agent.ex`
- [ ] 1.6.2 Define `agent_transformer` that:
  - Wraps generated Elm Architecture in Jido.Agent.Server
  - Implements `c:Jido.Agent.Server.init/1`
- [ ] 1.6.3 Define `signal_handler_transformer` that:
  - Implements `c:Jido.Agent.Server.handle_signal/2`
  - Routes incoming JidoSignal to update/2
- [ ] 1.6.4 Create `UnifiedUi.Agent` helper module with:
  - `start_component/3` - Starts a UI component as an agent
  - `stop_component/1` - Stops a running component agent
- [ ] 1.6.5 Define supervision tree for UI component agents
- [ ] 1.6.6 Implement agent registration in registry

**Implementation Notes:**
- Components are Jido.Agent.Server processes with unique names
- Agent name typically: `{:ui_component, component_id}`
- Signal routing uses JidoSignal's addressing mechanism
- Supervision strategy: `:one_for_one`

**Unit Tests for Section 1.6:**
- [ ] Test agent_transformer generates Jido.Agent.Server compliant module
- [ ] Test component starts as an agent
- [ ] Test component stops cleanly
- [ ] Test signal routing to update function
- [ ] Test component registration in registry

---

## 1.7 Verifiers and Validation

- [ ] **Task 1.7** Implement Spark verifiers for compile-time DSL validation

Create verifiers that perform semantic validation of DSL definitions, catching errors at compile time.

- [ ] 1.7.1 Create `lib/unified_ui/dsl/transformers/verifiers.ex`
- [ ] 1.7.2 Define `unique_id_verifier` that:
  - Scans all widgets in a component
  - Ensures all `id` attributes are unique within scope
- [ ] 1.7.3 Define `signal_reference_verifier` that:
  - Checks all `on_click`, `on_change`, etc. handlers
  - Verifies referenced signals are defined
- [ ] 1.7.4 Define `required_attribute_verifier` that:
  - Checks all required options are provided
  - Validates option types match schema
- [ ] 1.7.5 Register all verifiers in DSL extension
- [ ] 1.7.6 Add helpful error messages with code location hints

**Implementation Notes:**
- Verifiers use `Spark.Dsl.Verifier` behaviour
- Each verifier implements `verify(dsl_state)` function
- Returns `:ok` or `{:error, message}` with spark error format
- Error messages include `{module, line}` location

**Unit Tests for Section 1.7:**
- [ ] Test unique_id_verifier passes with unique IDs
- [ ] Test unique_id_verifier fails with duplicate IDs
- [ ] Test signal_reference_verifier passes with defined signals
- [ ] Test signal_reference_verifier fails with undefined signals
- [ ] Test required_attribute_verifier passes with all required
- [ ] Test error messages include correct locations

---

## 1.8 Info Module Generation

- [ ] **Task 1.8** Set up Spark.InfoGenerator for DSL introspection

Create the Info module that provides convenient functions to query the DSL state at compile time and runtime.

- [ ] 1.8.1 Configure `Spark.InfoGenerator` in DSL extension
- [ ] 1.8.2 Generate `UnifiedUi.Info` module
- [ ] 1.8.3 Add info functions:
  - `widgets/1` - Get all widgets from a DSL module
  - `layouts/1` - Get all layouts from a DSL module
  - `signals/1` - Get all signals from a DSL module
  - `styles/1` - Get all styles from a DSL module
- [ ] 1.8.4 Document Info module usage
- [ ] 1.8.5 Test Info functions work correctly

**Implementation Notes:**
- Spark.InfoGenerator automatically creates Info module
- Info functions used by transformers and renderers
- Provides runtime introspection capabilities

**Unit Tests for Section 1.8:**
- [ ] Test Info module is generated
- [ ] Test widgets/1 returns widget list
- [ ] Test layouts/1 returns layout list
- [ ] Test signals/1 returns signal list
- [ ] Test styles/1 returns style list

---

## 1.9 Basic Documentation Setup

- [ ] **Task 1.9** Set up ExDoc for API documentation generation

Configure ExDoc and add basic documentation to all public modules.

- [ ] 1.9.1 Add `:ex_doc` to dev dependencies in mix.exs
- [ ] 1.9.2 Configure ExDoc in mix.exs
- [ ] 1.9.3 Add `@moduledoc` to all public modules
- [ ] 1.9.4 Add `@doc` to all public functions
- [ ] 1.9.5 Generate documentation with `mix docs`
- [ ] 1.9.6 Verify documentation builds without warnings

**Implementation Notes:**
- Use proper moduledoc/doc format
- Include examples where applicable
- Auto-publish to HexDocs on release

**Unit Tests for Section 1.9:**
- [ ] Test docs build without errors
- [ ] Test all modules documented
- [ ] Test all functions documented

---

## 1.10 Phase 1 Integration Tests

Comprehensive integration tests to verify all foundation components work together correctly.

- [ ] 1.10.1 Test complete DSL compilation with valid UI definition
- [ ] 1.10.2 Test Elm Architecture code generation from DSL
- [ ] 1.10.3 Test Jido.Agent.Server integration and lifecycle
- [ ] 1.10.4 Test signal emission and reception between components
- [ ] 1.10.5 Test IUR generation from DSL definitions
- [ ] 1.10.6 Test verifiers catch all invalid configurations
- [ ] 1.10.7 Test component startup and shutdown
- [ ] 1.10.8 Test Info module introspection

**Implementation Notes:**
- Integration tests go in `test/unified_ui/integration/phase1_test.exs`
- Use `async: false` for tests involving global state or agents
- Create example UI components for testing
- Test both success and failure paths

**Unit Tests for Section 1.10:**
- [ ] Test valid UI compiles and generates code
- [ ] Test Elm Architecture init/update/view are generated
- [ ] Test agent starts with correct initial state
- [ ] Test signal routing between agents works
- [ ] Test IUR tree matches expected structure
- [ ] Test verifier errors prevent compilation
- [ ] Test no resource leaks on shutdown

---

## Success Criteria

1. **Project Structure**: Clean directory structure following Spark conventions
2. **DSL Compiles**: A UI defined with the DSL compiles without errors
3. **IUR Defined**: Intermediate UI Representation designed and documented
4. **Signals Work**: Signal definition and emission work correctly
5. **Elm Architecture**: Generated components follow init/update/view pattern
6. **Jido Integration**: Components run as Jido.Agent.Server processes
7. **Validation**: Verifiers catch invalid configurations at compile time
8. **Introspection**: Info module provides DSL query functions
9. **Documentation**: All public modules and functions documented
10. **Test Coverage**: 80%+ coverage for all foundation code

---

## Critical Files

**New Files:**
- `mix.exs` - Library configuration and dependencies
- `lib/unified_ui.ex` - Main library module
- `lib/unified_ui/dsl/extension.ex` - Spark DSL Extension
- `lib/unified_ui/dsl/entities/signals.ex` - Signal entity definitions
- `lib/unified_ui/dsl/sections/` - DSL section definitions
- `lib/unified_ui/dsl/transformers/elm_arch.ex` - Elm Architecture transformers
- `lib/unified_ui/dsl/transformers/jido_agent.ex` - Jido Agent transformers
- `lib/unified_ui/dsl/transformers/verifiers.ex` - Compile-time verifiers
- `lib/unified_ui/iur/element.ex` - IUR protocol
- `lib/unified_ui/iur/widgets.ex` - IUR widget structs
- `lib/unified_ui/iur/layouts.ex` - IUR layout structs
- `lib/unified_ui/iur/styles.ex` - IUR style structs
- `lib/unified_ui/info.ex` - Spark.InfoGenerated module
- `lib/unified_ui/elm_architecture.ex` - Elm Architecture behaviour
- `lib/unified_ui/signals.ex` - Signal helpers
- `lib/unified_ui/agent.ex` - Agent lifecycle helpers
- `config/config.exs` - Application configuration
- `.formatter.exs` - Code formatter configuration
- `test/unified_ui/integration/phase1_test.exs` - Integration tests

**Dependencies:**
- None (first phase)

---

## Dependencies

**This phase has no dependencies** and establishes the foundation for all subsequent phases.

**Phases that depend on this phase:**
- Phase 2: Core Widgets & Layouts (depends on DSL foundation, IUR, signals)
- Phase 3: Renderer Implementations (depends on IUR and DSL structure)
- Phase 4: Advanced Features & Styling (depends on complete foundation)
- Phase 5: Testing & Tooling (depends on all previous phases)
