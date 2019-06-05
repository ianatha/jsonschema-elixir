defmodule Test.MixProject do
  use Mix.Project

  def project do
    [
      app: :elxir_jsonschema,
      version: "0.1.0",
      elixir: "~> 1.7",
      erlc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {JSONSchema.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
        {:slack, "~> 0.18.0"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:tap, "~> 0.1.5"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
