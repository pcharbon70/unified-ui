defmodule UnifiedUi.Dsl.Transformers.UpdateTransformerTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias UnifiedUi.Dsl.Transformers.UpdateTransformer

  defmodule RouteMfaFixture do
    @moduledoc false

    def apply_click(state, %Signal{data: data}, route, marker) do
      Map.put(state, marker, {route.source, Map.get(data, :widget_id)})
    end
  end

  describe "module availability" do
    test "transformer module is compiled" do
      assert Code.ensure_loaded?(UpdateTransformer)
    end
  end

  describe "generated update/2 behavior" do
    test "click route merges static payload for matched widget" do
      module =
        compile_fixture("""
        vbox do
          button "Save", id: :save_btn, on_click: {:save_clicked, %{mode: :saved}}
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.button.clicked", %{widget_id: :save_btn, action: :save_clicked})

      assert %{mode: :saved} = module.update(state, signal)
    end

    test "route matching prefers widget source id when actions are shared" do
      module =
        compile_fixture("""
        vbox do
          button "Primary", id: :primary_btn, on_click: {:select, %{selected: :primary}}
          button "Secondary", id: :secondary_btn, on_click: {:select, %{selected: :secondary}}
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.button.clicked", %{widget_id: :secondary_btn, action: :select})

      assert %{selected: :secondary} = module.update(state, signal)
    end

    test "change route writes signal value into state using input id as key" do
      module =
        compile_fixture("""
        vbox do
          text_input :email, on_change: :email_changed
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.input.changed", %{widget_id: :email, value: "test@example.com"})

      assert %{email: "test@example.com"} = module.update(state, signal)
    end

    test "submit route merges static payload and submitted form data" do
      module =
        compile_fixture("""
        vbox do
          text_input :email, form_id: :login_form, on_submit: {:submit_login, %{submitted: true}}
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.form.submitted", %{
          form_id: :login_form,
          data: %{email: "user@example.com"}
        })

      updated = module.update(state, signal)

      assert updated.submitted == true
      assert updated.email == "user@example.com"
    end

    test "map signals are supported in addition to Jido.Signal structs" do
      module =
        compile_fixture("""
        vbox do
          text_input :username, on_change: :username_changed
        end
        """)

      state = module.init([])

      signal = %{
        type: "unified.input.changed",
        data: %{widget_id: :username, value: "pascal"}
      }

      assert %{username: "pascal"} = module.update(state, signal)
    end

    test "mfa routes are invoked for matched handlers" do
      module =
        compile_fixture("""
        vbox do
          button "Run",
            id: :run_btn,
            on_click: {#{inspect(RouteMfaFixture)}, :apply_click, [:handled]}
        end
        """)

      state = module.init([])

      signal = build_signal!("unified.button.clicked", %{widget_id: :run_btn, action: :ignored})

      assert %{handled: {:run_btn, :run_btn}} = module.update(state, signal)
    end

    test "custom handler overrides still work for matched routes" do
      module =
        compile_fixture("""
        vbox do
          text_input :count_input, on_change: :count_changed
        end

        def handle_change_signal(state, _signal, _route) do
          Map.put(state, :total, 42)
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.input.changed", %{widget_id: :count_input, value: "123"})

      assert %{total: 42} = module.update(state, signal)
    end

    test "unmatched signals return state unchanged" do
      module =
        compile_fixture("""
        vbox do
          button "Increment", id: :inc_btn, on_click: :increment
        end
        """)

      state = module.init([])
      signal = build_signal!("unknown.signal", %{widget_id: :inc_btn})

      assert state == module.update(state, signal)
    end
  end

  defp compile_fixture(body) do
    module = unique_fixture_module()

    source = """
    defmodule #{inspect(module)} do
      @behaviour UnifiedUi.ElmArchitecture
      use UnifiedUi.Dsl

      #{body}
    end
    """

    Code.compile_string(source)
    module
  end

  defp unique_fixture_module do
    Module.concat([
      UnifiedUi,
      UpdateTransformerFixture,
      :"M#{System.unique_integer([:positive])}"
    ])
  end

  defp build_signal!(type, data) do
    {:ok, signal} = Signal.new(type: type, data: data, source: "/unified_ui/test")
    signal
  end
end
