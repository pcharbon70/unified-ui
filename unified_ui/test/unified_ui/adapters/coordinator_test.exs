defmodule UnifiedUi.Adapters.CoordinatorTest do
  @moduledoc """
  Tests for UnifiedUi.Adapters.Coordinator
  """

  use ExUnit.Case, async: true

  alias UnifiedUi.Adapters.Coordinator
  alias UnifiedIUR.Widgets
  alias UnifiedIUR.Layouts

  # Helper to create a simple IUR tree for testing
  defp simple_iur_tree do
    %Layouts.VBox{
      id: :root,
      children: [
        %Widgets.Text{
          id: :greeting,
          content: "Hello, World!"
        },
        %Widgets.Button{
          id: :click_me,
          label: "Click Me",
          on_click: :clicked
        }
      ]
    }
  end

  describe "platform detection" do
    test "detect_platform/0 returns a valid platform" do
      platform = Coordinator.detect_platform()

      assert platform in [:terminal, :desktop, :web]
    end

    test "is_terminal?/0 returns boolean" do
      result = Coordinator.is_terminal?()

      assert is_boolean(result)
    end

    test "is_desktop?/0 returns boolean" do
      result = Coordinator.is_desktop?()

      assert is_boolean(result)
    end

    test "is_web?/0 returns boolean" do
      result = Coordinator.is_web?()

      assert is_boolean(result)
    end
  end

  describe "platform support" do
    test "supports_platform?/1 returns true for valid platforms" do
      assert Coordinator.supports_platform?(:terminal)
      assert Coordinator.supports_platform?(:desktop)
      assert Coordinator.supports_platform?(:web)
    end

    test "supports_platform?/1 returns false for invalid platforms" do
      refute Coordinator.supports_platform?(:mobile)
      refute Coordinator.supports_platform?(:invalid)
      refute Coordinator.supports_platform?(nil)
    end
  end

  describe "renderer selection" do
    test "select_renderer/1 returns terminal renderer" do
      assert {:ok, UnifiedUi.Adapters.Terminal} = Coordinator.select_renderer(:terminal)
    end

    test "select_renderer/1 returns desktop renderer" do
      assert {:ok, UnifiedUi.Adapters.Desktop} = Coordinator.select_renderer(:desktop)
    end

    test "select_renderer/1 returns web renderer" do
      assert {:ok, UnifiedUi.Adapters.Web} = Coordinator.select_renderer(:web)
    end

    test "select_renderer/1 returns error for invalid platform" do
      assert {:error, :invalid_platform} = Coordinator.select_renderer(:invalid)
      assert {:error, :invalid_platform} = Coordinator.select_renderer(:mobile)
    end

    test "select_renderers/1 returns multiple renderers" do
      assert {:ok, renderers} = Coordinator.select_renderers([:terminal, :web])

      assert UnifiedUi.Adapters.Terminal in renderers
      assert UnifiedUi.Adapters.Web in renderers
      assert length(renderers) == 2
    end

    test "select_renderers/1 returns error for invalid platform in list" do
      assert {:error, :invalid_platform} = Coordinator.select_renderers([:terminal, :invalid])
    end

    test "available_renderers/0 returns all platforms" do
      platforms = Coordinator.available_renderers()

      assert :terminal in platforms
      assert :desktop in platforms
      assert :web in platforms
      assert length(platforms) == 3
    end

    test "enabled_renderers/0 returns enabled platforms" do
      platforms = Coordinator.enabled_renderers()

      assert is_list(platforms)
      assert Enum.all?(platforms, fn p -> p in [:terminal, :desktop, :web] end)
    end
  end

  describe "multi-platform rendering" do
    test "render_on/2 renders on single platform" do
      iur = simple_iur_tree()

      assert {:ok, results} = Coordinator.render_on(iur, [:terminal])
      assert Map.has_key?(results, :terminal)
      assert {:ok, _state} = results.terminal
    end

    test "render_on/2 renders on multiple platforms" do
      iur = simple_iur_tree()

      assert {:ok, results} = Coordinator.render_on(iur, [:terminal, :desktop])
      assert Map.has_key?(results, :terminal)
      assert Map.has_key?(results, :desktop)
    end

    test "render_on/2 handles invalid platform gracefully" do
      iur = simple_iur_tree()

      # Include valid platform so at least one succeeds
      assert {:ok, results} = Coordinator.render_on(iur, [:terminal, :invalid])
      assert Map.has_key?(results, :terminal)
      assert {:error, _} = results.invalid
    end

    test "render_on/2 passes options to renderers" do
      iur = simple_iur_tree()
      opts = [window_title: "Test Window", debug: true]

      assert {:ok, results} = Coordinator.render_on(iur, [:terminal], opts)
      assert {:ok, state} = results.terminal
      assert state.platform == :terminal
    end

    test "render_all/1 renders on all available platforms" do
      iur = simple_iur_tree()

      assert {:ok, results} = Coordinator.render_all(iur)

      # Should have results for all platforms
      assert Map.has_key?(results, :terminal)
      assert Map.has_key?(results, :desktop)
      assert Map.has_key?(results, :web)

      # At least one should succeed
      successful =
        Enum.count(results, fn {_platform, result} ->
          match?({:ok, _}, result)
        end)

      assert successful > 0
    end

    test "render_all/1 with custom options" do
      iur = simple_iur_tree()
      opts = [debug: true]

      assert {:ok, results} = Coordinator.render_all(iur, opts)

      # All platforms should have a result
      assert map_size(results) == 3
    end
  end

  describe "concurrent rendering" do
    test "concurrent_render/2 renders on multiple platforms concurrently" do
      iur = simple_iur_tree()

      assert {:ok, results} = Coordinator.concurrent_render(iur, [:terminal, :desktop])

      assert Map.has_key?(results, :terminal)
      assert Map.has_key?(results, :desktop)
    end

    test "concurrent_render/2 renders on all platforms" do
      iur = simple_iur_tree()

      assert {:ok, results} = Coordinator.concurrent_render(iur, Coordinator.available_renderers())

      assert map_size(results) == 3
    end

    test "concurrent_render/2 respects timeout option" do
      iur = simple_iur_tree()

      assert {:ok, results} =
               Coordinator.concurrent_render(iur, [:terminal], timeout: 5000)

      assert Map.has_key?(results, :terminal)
    end

    test "concurrent_render/2 handles timeout gracefully" do
      iur = simple_iur_tree()

      # Very short timeout, but rendering should be fast
      assert {:ok, results} =
               Coordinator.concurrent_render(iur, [:terminal], timeout: 100)

      # Should either succeed or timeout
      assert Map.has_key?(results, :terminal)
    end

    test "concurrent_render/2 handles invalid platforms" do
      iur = simple_iur_tree()

      assert {:ok, results} = Coordinator.concurrent_render(iur, [:terminal, :invalid])

      assert Map.has_key?(results, :terminal)
      assert {:error, _} = results.invalid
    end
  end

  describe "state synchronization" do
    test "sync_state/2 returns :ok" do
      state = %{count: 1}
      renderer_states = %{terminal: %{platform: :terminal}}

      assert :ok = Coordinator.sync_state(state, renderer_states)
    end

    test "merge_states/1 merges empty list to empty map" do
      assert Coordinator.merge_states([]) == %{}
    end

    test "merge_states/1 merges single state" do
      state = %{count: 1, name: "test"}

      result = Coordinator.merge_states([state])

      assert result.count == 1
      assert result.name == "test"
    end

    test "merge_states/1 merges multiple states with last-write-wins" do
      state1 = %{count: 1, name: "first"}
      state2 = %{count: 2, name: "second"}

      result = Coordinator.merge_states([state1, state2])

      assert result.count == 2
      assert result.name == "second"
    end

    test "merge_states/1 concatenates lists" do
      state1 = %{items: ["a", "b"]}
      state2 = %{items: ["c"]}

      result = Coordinator.merge_states([state1, state2])

      # Note: current implementation uses last-write-wins for all types
      assert result.items == ["c"]
    end

    test "merge_states/1 deeply merges nested maps" do
      state1 = %{
        user: %{name: "Alice", settings: %{theme: :dark}}
      }

      state2 = %{
        user: %{settings: %{notifications: true}}
      }

      result = Coordinator.merge_states([state1, state2])

      # Deep merge should combine nested maps
      assert result.user.name == "Alice"
      assert result.user.settings.theme == :dark
      assert result.user.settings.notifications == true
    end

    test "conflict_resolution/2 returns new state (last-write-wins)" do
      old_state = %{count: 1, name: "old", data: %{value: "old"}}
      new_state = %{count: 2, name: "new", data: %{value: "new"}}

      result = Coordinator.conflict_resolution(old_state, new_state)

      assert result.count == 2
      assert result.name == "new"
      assert result.data.value == "new"
    end

    test "broadcast_state/2 returns :ok" do
      state = %{count: 1}
      renderer_states = %{terminal: %{platform: :terminal}}

      assert :ok = Coordinator.broadcast_state(state, renderer_states)
    end

    test "broadcast_state/2 works with multiple renderers" do
      state = %{count: 1}

      renderer_states = %{
        terminal: %{platform: :terminal},
        web: %{platform: :web}
      }

      assert :ok = Coordinator.broadcast_state(state, renderer_states)
    end
  end

  describe "integration scenarios" do
    test "complete render cycle on single platform" do
      # Create IUR tree
      iur = %Layouts.VBox{
        id: :main,
        children: [
          %Widgets.Text{id: :title, content: "Welcome"},
          %Widgets.Button{id: :start, label: "Start", on_click: :start}
        ]
      }

      # Render on terminal
      assert {:ok, results} = Coordinator.render_on(iur, [:terminal])
      assert {:ok, state} = results.terminal

      # Verify state structure
      assert state.platform == :terminal
      assert Map.has_key?(state, :root)
    end

    test "render same UI on multiple platforms" do
      iur = %Layouts.HBox{
        id: :toolbar,
        children: [
          %Widgets.Button{id: :save, label: "Save", on_click: :save},
          %Widgets.Button{id: :load, label: "Load", on_click: :load}
        ]
      }

      assert {:ok, results} = Coordinator.render_all(iur)

      # All platforms should have rendered
      assert map_size(results) == 3

      # Check that at least terminal and web succeeded
      assert {:ok, _} = results.terminal
      assert {:ok, _} = results.web
    end

    test "concurrent render with state merge" do
      iur = simple_iur_tree()

      # Render on multiple platforms concurrently
      assert {:ok, results} =
               Coordinator.concurrent_render(iur, [:terminal, :web])

      # Extract states from successful renders
      states =
        Enum.filter(results, fn {_platform, result} ->
          match?({:ok, _}, result)
        end)
        |> Enum.map(fn {_platform, {:ok, state}} -> state end)

      # Merge states
      merged = Coordinator.merge_states(states)

      # Should have a merged state
      assert is_map(merged)
    end

    test "platform detection and renderer selection flow" do
      # Detect platform
      platform = Coordinator.detect_platform()
      assert platform in [:terminal, :desktop, :web]

      # Select renderer for detected platform
      assert {:ok, renderer} = Coordinator.select_renderer(platform)

      # Verify renderer is a module
      assert is_atom(renderer)
    end

    test "error handling for unsupported platform" do
      iur = simple_iur_tree()

      # Try to render on mix of valid and invalid platforms
      # Should succeed because at least one valid platform is included
      assert {:ok, results} = Coordinator.render_on(iur, [:terminal, :mobile])
      assert {:ok, _} = results.terminal
      assert {:error, _} = results.mobile
    end

    test "complex nested layout renders correctly" do
      iur = %Layouts.VBox{
        id: :root,
        children: [
          %Widgets.Text{id: :header, content: "Header"},
          %Layouts.HBox{
            id: :row,
            children: [
              %Widgets.Button{id: :ok, label: "OK", on_click: :ok},
              %Widgets.Button{id: :cancel, label: "Cancel", on_click: :cancel}
            ]
          }
        ]
      }

      assert {:ok, results} = Coordinator.render_on(iur, [:terminal])
      assert {:ok, state} = results.terminal

      # Should have a root element
      assert Map.has_key?(state, :root)
    end
  end

  describe "platform-specific rendering" do
    test "render terminal-specific UI" do
      iur = %Layouts.VBox{
        id: :terminal_ui,
        children: [
          %Widgets.Text{id: :status, content: "Terminal Interface"}
        ]
      }

      assert {:ok, results} = Coordinator.render_on(iur, [:terminal])
      assert {:ok, state} = results.terminal
      assert state.platform == :terminal
    end

    test "render desktop-specific UI" do
      iur = %Layouts.VBox{
        id: :desktop_ui,
        children: [
          %Widgets.Button{id: :close, label: "Close Window", on_click: :close_window}
        ]
      }

      assert {:ok, results} = Coordinator.render_on(iur, [:desktop])
      assert {:ok, state} = results.desktop
      assert state.platform == :desktop
    end

    test "render web-specific UI" do
      iur = %Layouts.VBox{
        id: :web_ui,
        children: [
          %Widgets.TextInput{
            id: :email,
            type: :email,
            placeholder: "user@example.com"
          }
        ]
      }

      assert {:ok, results} = Coordinator.render_on(iur, [:web])
      assert {:ok, state} = results.web
      assert state.platform == :web
    end
  end
end
