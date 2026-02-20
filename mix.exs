defmodule UnifiedUi.MixProject do
  use Mix.Project

  def project do
    [
      app: :unified_ui,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {UnifiedUi.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spark, "~> 1.0"},
      {:jido, "~> 1.0"},
      {:jido_signal, "~> 1.0"},
      {:term_ui, github: "pcharbon70/term_ui", branch: "multi-renderer"},
      {:unified_iur, path: "../unified_iur"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A Spark-powered DSL for building multi-platform user interfaces in Elixir.

    Provides declarative UI definitions that compile to terminal, desktop, and web platforms.
    """
  end

  defp package do
    [
      name: "unified_ui",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/pcharbon70/unified_ui",
        "Changelog" => "https://github.com/pcharbon70/unified_ui/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "guides/getting-started.md",
        "guides/widget-reference.md"
      ],
      groups_for_extras: [
        Guides: ["guides/*.md"]
      ]
    ]
  end
end
