defmodule UnifiedUi.TestScreen do
  @moduledoc false
  @behaviour UnifiedUi.ElmArchitecture
  use UnifiedUi.Dsl

  ui do
    vbox do
      text "Hello"
    end
  end
end
