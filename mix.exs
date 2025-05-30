defmodule ElixirAST.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_ast,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_unit, "~> 1.12", only: :test}
    ]
  end
end
