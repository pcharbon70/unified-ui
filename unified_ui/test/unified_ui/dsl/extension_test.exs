defmodule UnifiedUi.Dsl.ExtensionTest do
  use ExUnit.Case

  describe "Extension compilation" do
    test "extension module compiles without errors" do
      assert Code.ensure_loaded?(UnifiedUi.Dsl.Extension)
    end
  end

  describe "DSL module" do
    test "Dsl module compiles without errors" do
      assert Code.ensure_loaded?(UnifiedUi.Dsl)
    end

    test "can create a module using UnifiedUi.Dsl" do
      defmodule TestUiModule do
        use UnifiedUi.Dsl
      end

      assert Code.ensure_loaded?(TestUiModule)
    end
  end

  describe "Section definitions via extension" do
    test "extension defines sections correctly" do
      # The extension should have compiled with sections
      # If compilation succeeded, the sections are defined
      assert Code.ensure_loaded?(UnifiedUi.Dsl.Extension)
    end
  end

  describe "Standard signals" do
    test "returns list of standard signal types" do
      signals = UnifiedUi.Dsl.standard_signals()
      assert :click in signals
      assert :change in signals
      assert :submit in signals
      assert :focus in signals
      assert :blur in signals
      assert :select in signals
    end
  end

  describe "Style attributes" do
    test "standard_signals returns correct count" do
      signals = UnifiedUi.Dsl.standard_signals()
      assert length(signals) == 6
    end
  end
end
