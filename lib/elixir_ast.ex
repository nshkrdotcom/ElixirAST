defmodule ElixirAST do
  @moduledoc """
  ElixirAST: Compile-Time AST Instrumentation Engine (Placeholder)
  """
  alias ElixirAST.Builder
  alias ElixirAST.Core.Parser
  alias ElixirAST.Core.Transformer # Added

  def new(opts \\ []) do
    Builder.new(opts)
  end

  def parse(source_code) when is_binary(source_code) do
    Parser.parse(source_code)
  end

  # New function
  def instrument_functions(config, target_spec, instrumentation_opts \\ []) do
    Builder.instrument_functions(config, target_spec, instrumentation_opts)
  end

  # New function
  def transform(config, ast) do
    Transformer.transform(config, ast)
  end

  # New function
  def parse_and_transform(config, source_code) do
    with {:ok, ast} <- parse(source_code),
         {:ok, instrumented_ast} <- transform(config, ast) do
      {:ok, instrumented_ast}
    else
      error -> error # Pass through any error from parse or transform
    end
  end

  # New function
  def validate(config) do
    Builder.validate(config)
  end
end
