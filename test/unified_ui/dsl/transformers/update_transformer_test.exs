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

    test "pick_list on_select routes are handled as change routes" do
      module =
        compile_fixture("""
        vbox do
          pick_list :country_select, [{"us", "United States"}, {"ca", "Canada"}],
            on_select: :country_selected
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.input.changed", %{widget_id: :country_select, value: "ca"})

      assert %{country_select: "ca"} = module.update(state, signal)
    end

    test "pick_list searchable routes expose filtered options from query payload" do
      module =
        compile_fixture("""
        vbox do
          pick_list :country_select, [{"us", "United States"}, {"ca", "Canada"}, {"cm", "Cameroon"}],
            searchable: true,
            on_select: :country_selected
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.input.changed", %{
          widget_id: :country_select,
          query: "ca"
        })

      updated = module.update(state, signal)

      assert updated.country_select_search_query == "ca"

      assert [
               %{value: "ca", label: "Canada"},
               %{value: "cm", label: "Cameroon"}
             ] = updated.country_select_filtered_options
    end

    test "theme selector pick_list updates theme key in runtime state" do
      module =
        compile_fixture("""
        vbox do
          pick_list :theme, [{:light, "Light"}, {:dark, "Dark"}], on_select: :theme_selected
        end
        """)

      signal = build_signal!("unified.input.changed", %{widget_id: :theme, value: "dark"})
      updated_state = module.update(module.init([]), signal)

      assert updated_state.theme == "dark"
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

    test "form_builder on_submit routes are handled as submit routes" do
      module =
        compile_fixture("""
        vbox do
          form_builder :profile_form, [%{name: :email, type: :email}],
            on_submit: {:profile_saved, %{saved: true}}
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.form.submitted", %{
          form_id: :profile_form,
          data: %{email: "user@example.com"}
        })

      updated = module.update(state, signal)

      assert updated.saved == true
      assert updated.email == "user@example.com"
      assert updated.profile_form_valid == true
      assert updated.profile_form_errors == %{}
    end

    test "form_builder routes attach validation errors when submitted data is invalid" do
      module =
        compile_fixture("""
        vbox do
          form_builder :profile_form, [
            %{name: :email, type: :email, required: true},
            %{name: :age, type: :number, required: true},
            %{name: :country, type: :select, options: [{"us", "United States"}, {"ca", "Canada"}]}
          ],
            on_submit: :profile_saved
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.form.submitted", %{
          form_id: :profile_form,
          data: %{email: "not-an-email", age: "twelve", country: "xx"}
        })

      updated = module.update(state, signal)

      assert updated.profile_form_valid == false
      assert updated.profile_form_errors.email == [:invalid_email]
      assert updated.profile_form_errors.age == [:invalid_number]
      assert updated.profile_form_errors.country == [:invalid_option]
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

    test "dialog close routes are handled as click routes" do
      module =
        compile_fixture("""
        vbox do
          dialog :settings_dialog, "Settings", "Dialog body",
            on_close: {:close_settings, %{closed: true}}
        end
        """)

      state = module.init([])

      signal =
        build_signal!("unified.button.clicked", %{
          widget_id: :settings_dialog,
          action: :close_settings
        })

      assert %{closed: true} = module.update(state, signal)
    end

    test "modal dialogs block background click routes until closed" do
      module =
        compile_fixture("""
        vbox do
          button "Background",
            id: :background_btn,
            on_click: {:background_clicked, %{background_clicked: true}}

          alert_dialog :confirm_dialog, "Confirm", "Are you sure?",
            on_confirm: {:confirm_clicked, %{confirm_clicked: true}}
        end
        """)

      state = module.init([])

      background_signal =
        build_signal!("unified.button.clicked", %{
          widget_id: :background_btn,
          action: :background_clicked
        })

      # Background click is blocked while the modal is active (default visible: true).
      assert state == module.update(state, background_signal)

      modal_signal =
        build_signal!("unified.button.clicked", %{
          widget_id: :confirm_dialog,
          action: :confirm_clicked
        })

      assert %{confirm_clicked: true} = module.update(state, modal_signal)
    end

    test "modal blocking can be disabled through modal visibility state flags" do
      module =
        compile_fixture("""
        vbox do
          button "Background",
            id: :background_btn,
            on_click: {:background_clicked, %{background_clicked: true}}

          dialog :confirm_dialog, "Confirm", "Are you sure?"
        end
        """)

      state = module.init([]) |> Map.put(:confirm_dialog_visible, false)

      signal =
        build_signal!("unified.button.clicked", %{
          widget_id: :background_btn,
          action: :background_clicked
        })

      assert %{background_clicked: true} = module.update(state, signal)
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
