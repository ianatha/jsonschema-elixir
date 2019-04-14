defmodule JSONSchema.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonschema_elixir,
      version: "0.0.1",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:dialyxir, "~> 0.4", only: [:dev]}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE*"],
      maintainers: ["Ian W. Atha"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/ianatha/jsonschema_elixir"}
    ]
  end
end
