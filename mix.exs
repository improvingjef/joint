defmodule Joint.MixProject do
  use Mix.Project

  def project do
    [
      app: :joint,
      version: "0.1.0",
      elixir: "~> 1.19-rc",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    application(Mix.env())
  end

  def application(:test) do
    [
      mod: {Joint.Application, []},
      extra_applications: [:logger]
    ]
  end

  def application(_) do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.16"}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  def aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "orders", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
