defmodule UnifiedUi.TestScreen do
  @behaviour UnifiedUi.ElmArchitecture
  use UnifiedUi.Dsl

  ui do
    vbox do
      text "Hello"
    end
  end
end
