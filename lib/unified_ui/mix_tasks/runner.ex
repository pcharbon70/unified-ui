defmodule UnifiedUi.MixTasks.Runner do
  @moduledoc false

  @spec run_task(String.t(), [String.t()]) :: any()
  def run_task(task, args) do
    Mix.Task.reenable(task)
    Mix.Task.run(task, args)
  end
end
