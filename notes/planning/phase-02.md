# Phase 2: Core Widgets & Layouts

This phase implements the core widget entities and layout containers that form the building blocks of any UI. These widgets and layouts are defined once in the DSL and work across all platforms through the IUR and renderer system.

---

## 2.1 Basic Widget Entities

- [ ] **Task 2.1** Define Spark.Dsl.Entity structs for core widgets

Create entity definitions for the foundational widgets: button, text, label, and text_input.

- [ ] 2.1.1 Create `lib/unified_ui/dsl/entities/widgets.ex`
- [ ] 2.1.2 Define `@button_entity` with schema:
  - args: `[:label]`
  - options: `id`, `on_click`, `disabled`, `style`, `visible`
- [ ] 2.1.3 Define `@text_entity` with schema:
  - args: `[:content]`
  - options: `id`, `style`, `visible`
- [ ] 2.1.4 Define `@label_entity` with schema:
  - args: `[:for, text]`
  - options: `id`, `style`, `visible`
- [ ] 2.1.5 Define `@text_input_entity` with schema:
  - args: `[:id]`
  - options: `value`, `placeholder`, `type`, `on_change`, `on_submit`, `disabled`, `style`, `visible`
- [ ] 2.1.6 Create corresponding target structs:
  - `UnifiedUi.Widgets.Button`
  - `UnifiedUi.Widgets.Text`
  - `UnifiedUi.Widgets.Label`
  - `UnifiedUi.Widgets.TextInput`
- [ ] 2.1.7 Create corresponding IUR structs
- [ ] 2.1.8 Add comprehensive `@doc` strings to each entity

**Implementation Notes:**
- `on_click` accepts: atom (signal name), `{atom, payload}`, or `fn -> ... end`
- `on_change` for text_input receives new value as argument
- Target structs store parsed DSL values for later use

**Unit Tests for Section 2.1:**
- [ ] Test button entity with required label argument
- [ ] Test button entity with all optional options
- [ ] Test text entity with content argument
- [ ] Test label entity with for and text arguments
- [ ] Test text_input entity with required id argument
- [ ] Test text_input with different type options
- [ ] Test on_click accepts various formats
- [ ] Verify target structs are created correctly

---

## 2.2 Basic Layout Entities

- [ ] **Task 2.2** Define Spark.Dsl.Entity structs for basic layout containers

Create entity definitions for the foundational layout containers: vbox (vertical box) and hbox (horizontal box).

- [ ] 2.2.1 Create `lib/unified_ui/dsl/entities/layouts.ex`
- [ ] 2.2.2 Define `@vbox_entity` with schema:
  - args: `[:children]`
  - options: `id`, `spacing`, `padding`, `align_items`, `justify_content`, `style`, `visible`
- [ ] 2.2.3 Define `@hbox_entity` with schema:
  - args: `[:children]`
  - options: `id`, `spacing`, `padding`, `align_items`, `justify_content`, `style`, `visible`
- [ ] 2.2.4 Create corresponding target structs:
  - `UnifiedUi.Layouts.VBox`
  - `UnifiedUi.Layouts.HBox`
- [ ] 2.2.5 Create corresponding IUR structs
- [ ] 2.2.6 Define `align_items` values: `:start`, `:center`, `:end`, `:stretch`
- [ ] 2.2.7 Define `justify_content` values: `:start`, `:center`, `:end`, `:space_between`, `:space_around`
- [ ] 2.2.8 Add comprehensive `@doc` strings with examples

**Implementation Notes:**
- Children argument accepts list of widget/layout atoms or nested definitions
- `spacing` is platform-dependent unit
- Layout entities are recursive (can contain other layouts)

**Unit Tests for Section 2.2:**
- [ ] Test vbox entity with children list
- [ ] Test hbox entity with children list
- [ ] Test vbox with nested layouts
- [ ] Test hbox with nested layouts
- [ ] Test spacing option
- [ ] Test padding option
- [ ] Test align_items option with all valid values
- [ ] Test justify_content option with all valid values
- [ ] Test invalid align_items value raises error
- [ ] Verify target structs store children correctly

---

## 2.3 Widget State Integration

- [ ] **Task 2.3** Implement state management for widgets in the Elm Architecture

Update the Elm Architecture transformers to properly handle widget state and state interpolation.

- [ ] 2.3.1 Update `init_transformer` to extract widget initial state
- [ ] 2.3.2 Update `view_transformer` to interpolate state into widget properties
- [ ] 2.3.3 Implement state binding for text_input (value binding)
- [ ] 2.3.4 Implement state binding for disabled attribute
- [ ] 2.3.5 Implement state binding for visible attribute
- [ ] 2.3.6 Add state update helpers for common patterns

**Implementation Notes:**
- State values referenced as `{:state, :key}` in DSL
- View transformer replaces references with actual state values
- Common patterns: increment, toggle, set value

**Unit Tests for Section 2.3:**
- [ ] Test widget state initializes correctly
- [ ] Test state interpolation in view works
- [ ] Test text_input value binding
- [ ] Test disabled state binding
- [ ] Test visible state binding
- [ ] Test state update helpers work

---

## 2.4 Signal Wiring

- [ ] **Task 2.4** Implement signal wiring for widget events

Connect widget event handlers to the signal system for inter-component communication.

- [ ] 2.4.1 Update `update_transformer` to generate signal handler clauses
- [ ] 2.4.2 Implement on_click signal emission
- [ ] 2.4.3 Implement on_change signal emission with payload
- [ ] 2.4.4 Implement on_submit signal emission
- [ ] 2.4.5 Add signal payload extraction helpers
- [ ] 2.4.6 Test signal routing to component agents

**Implementation Notes:**
- Signal handlers generate JidoSignal envelopes
- Payload includes event data (e.g., input value, coordinates)
- Signals dispatched via Jido.Agent.Server

**Unit Tests for Section 2.4:**
- [ ] Test on_click emits correct signal
- [ ] Test on_change emits signal with payload
- [ ] Test on_submit emits signal with form data
- [ ] Test signal reaches target agent
- [ ] Test signal payload is correct

---

## 2.5 IUR Tree Building

- [ ] **Task 2.5** Implement IUR tree building from DSL definitions

Create the system that traverses the DSL definition and builds the corresponding IUR tree.

- [ ] 2.5.1 Create `lib/unified_ui/iur/builder.ex`
- [ ] 2.5.2 Implement `build/1` function that traverses DSL state
- [ ] 2.5.3 Implement widget-to-IUR conversion for all basic widgets
- [ ] 2.5.4 Implement layout-to-IUR conversion for all basic layouts
- [ ] 2.5.5 Handle nested structures recursively
- [ ] 2.5.6 Apply style resolution during build
- [ ] 2.5.7 Validate IUR tree structure

**Implementation Notes:**
- Builder uses Spark.Dsl.Extension.get_entities to read DSL
- Each entity type has corresponding build function
- Recursion handles arbitrary nesting depth
- Styles resolved and merged during build

**Unit Tests for Section 2.5:**
- [ ] Test build creates correct IUR for single widget
- [ ] Test build creates correct IUR for nested layouts
- [ ] Test build handles deeply nested structures
- [ ] Test build applies styles correctly
- [ ] Test build validates structure

---

## 2.6 Enhanced Verifiers

- [ ] **Task 2.6** Enhance verifiers for core widgets and layouts

Update and expand verifiers to handle validation of the new widget and layout entities.

- [ ] 2.6.1 Update `unique_id_verifier` to handle all widgets
- [ ] 2.6.2 Add `layout_structure_verifier` for layout validation
- [ ] 2.6.3 Add `signal_handler_verifier` for signal reference validation
- [ ] 2.6.4 Add `style_reference_verifier` for style name validation
- [ ] 2.6.5 Add `state_reference_verifier` for state key validation
- [ ] 2.6.6 Improve error messages with specific locations

**Implementation Notes:**
- Verifiers run after transformers
- Provide clear, actionable error messages
- Include file and line number in errors

**Unit Tests for Section 2.6:**
- [ ] Test unique_id_verifier catches duplicate IDs
- [ ] Test layout_structure_verifier catches invalid nesting
- [ ] Test signal_handler_verifier catches undefined signals
- [ ] Test style_reference_verifier catches undefined styles
- [ ] Test state_reference_verifier catches invalid state keys

---

## 2.7 Form Support

- [ ] **Task 2.7** Add basic form support for input widgets

Create the foundational pieces for form handling with input widgets.

- [ ] 2.7.1 Define form association attributes for text_input
- [ ] 2.7.2 Add form_id option to input widgets
- [ ] 2.7.3 Implement form data collection helpers
- [ ] 2.7.4 Add form submission signal helpers
- [ ] 2.7.5 Create basic form validation helpers

**Implementation Notes:**
- Forms group inputs by form_id
- Submission collects all input values
- Validation runs before submit signal

**Unit Tests for Section 2.7:**
- [ ] Test inputs can be associated with form
- [ ] Test form submission collects all values
- [ ] Test form validation works
- [ ] Test form submit signal includes form data

---

## 2.8 Style System Foundation

- [ ] **Task 2.8** Create the foundational style system

Implement the basic style system that will be expanded in later phases.

- [ ] 2.8.1 Define `@style_entity` with schema:
  - args: `[:name]`
  - options: `attributes`, `extends`
- [ ] 2.8.2 Create `UnifiedUi.Styles.Style` target struct
- [ ] 2.8.3 Create IUR style struct
- [ ] 2.8.4 Define base style attributes:
  - `fg` - foreground color
  - `bg` - background color
  - `attrs` - list of attributes (:bold, :italic, :underline)
- [ ] 2.8.5 Create style resolver module
- [ ] 2.8.6 Implement style merge function
- [ ] 2.8.7 Add inline style support (keyword list)

**Implementation Notes:**
- Styles can extend other styles for inheritance
- Inline styles merged with named styles
- Platform-specific rendering handled by renderers

**Unit Tests for Section 2.8:**
- [ ] Test style entity with attributes
- [ ] Test style entity with extends
- [ ] Test style resolver works
- [ ] Test style merge works
- [ ] Test inline styles apply correctly
- [ ] Test style inheritance works

---

## 2.9 DSL Module

- [ ] **Task 2.9** Create the main DSL module for users

Create the primary `UnifiedUi.Dsl` module that developers will use in their UI definitions.

- [ ] 2.9.1 Create `lib/unified_ui/dsl/dsl.ex`
- [ ] 2.9.2 Add `use Spark.Dsl` with default extensions
- [ ] 2.9.3 Import all DSL entities
- [ ] 2.9.4 Add `@moduledoc` with usage examples
- [ ] 2.9.5 Add `@before_compile` hook for code generation
- [ ] 2.9.6 Test DSL can be used in a module

**Implementation Notes:**
- This is the main entry point for users
- All entities imported for convenience
- Before_compile triggers transformers

**Unit Tests for Section 2.9:**
- [ ] Test DSL module compiles
- [ ] Test DSL can be used in a user module
- [ ] Test all entities are available
- [ ] Test example UI definition works

---

## 2.10 Phase 2 Integration Tests

Comprehensive integration tests to verify all core widgets and layouts work together correctly.

- [ ] 2.10.1 Test complete UI with all basic widgets
- [ ] 2.10.2 Test nested layouts (5+ levels deep)
- [ ] 2.10.3 Test state updates flow through widgets
- [ ] 2.10.4 Test signal emission and handling
- [ ] 2.10.5 Test form submission works
- [ ] 2.10.6 Test style application to all widgets
- [ ] 2.10.7 Test IUR tree builds correctly
- [ ] 2.10.8 Test verifiers catch all invalid configurations
- [ ] 2.10.9 Test complex example UI (50+ elements)

**Implementation Notes:**
- Create comprehensive example UI
- Test all widget types
- Test all layout combinations
- Test state and signal flows

**Unit Tests for Section 2.10:**
- [ ] Test example UI compiles
- [ ] Test all widgets render to IUR correctly
- [ ] Test state changes propagate
- [ ] Test signals route correctly
- [ ] Test styles apply correctly
- [ ] Test validation catches errors

---

## Success Criteria

1. **Widget Entities**: All basic widgets defined in DSL
2. **Layout Entities**: VBox and HBox layouts defined
3. **State Management**: Widget state integrates with Elm Architecture
4. **Signal Wiring**: Widget events emit signals correctly
5. **IUR Building**: DSL definitions build correct IUR trees
6. **Validation**: Enhanced verifiers catch widget/layout errors
7. **Forms**: Basic form support works
8. **Styles**: Foundational style system in place
9. **DSL Module**: Users can write UI definitions
10. **Test Coverage**: 80%+ coverage for all new code

---

## Critical Files

**New Files:**
- `lib/unified_ui/dsl/entities/widgets.ex` - Basic widget entities
- `lib/unified_ui/dsl/entities/layouts.ex` - Basic layout entities
- `lib/unified_ui/widgets/` - Widget target structs
- `lib/unified_ui/layouts/` - Layout target structs
- `lib/unified_ui/iur/widgets.ex` - IUR widget structs
- `lib/unified_ui/iur/layouts.ex` - IUR layout structs
- `lib/unified_ui/iur/builder.ex` - IUR tree builder
- `lib/unified_ui/dsl/transformers/elm_arch.ex` - Updated Elm Architecture transformers
- `lib/unified_ui/dsl/transformers/verifiers.ex` - Enhanced verifiers
- `lib/unified_ui/styles/` - Style system
- `lib/unified_ui/dsl/dsl.ex` - Main DSL module
- `test/unified_ui/integration/phase2_test.exs` - Integration tests

**Modified Files:**
- `lib/unified_ui/dsl/extension.ex` - Add new sections and entities
- `lib/unified_ui/info.ex` - Regenerated with new entities

---

## Dependencies

**Depends on:**
- Phase 1: Foundation (DSL structure, IUR, signals, Elm Architecture)

**Enables:**
- Phase 3: Renderer Implementations (widgets and layouts to render)
- Phase 4: Advanced Features & Styling (base to expand upon)
