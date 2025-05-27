defmodule ElixirASTTest do
  use ExUnit.Case, async: true
  alias ElixirAST

  describe "ElixirAST.new/1" do
    test "returns a default configuration struct" do
      config = ElixirAST.new()
      assert %ElixirAST.Builder{output_format: :simple} = config
    end

    test "accepts and sets options like output_format" do
      config = ElixirAST.new(output_format: :json)
      assert %ElixirAST.Builder{output_format: :json} = config
    end
  end

  describe "ElixirAST.parse/1" do
    test "parses a simple valid module string" do
      source = "defmodule MyMod do def my_func, do: :ok end"
      assert {:ok, _ast} = ElixirAST.parse(source)
    end

    test "assigns a basic node ID to the parsed AST" do
      source = "defmodule MyMod do def my_func, do: :ok end"
      {:ok, ast} = ElixirAST.parse(source)
      assert ElixirASTTest.AstMetadata.get(ast, :elixir_ast_node_id) == "node_0"
    end

    test "returns an error for invalid syntax" do
      source = "defmodule MyMod do def my_func, do: end" # Invalid syntax
      assert {:error, _reason} = ElixirAST.parse(source)
    end
  end

  # Helper to access metadata, assuming AST nodes are tuples or have metadata field
  defmodule AstMetadata do
    def get(node, key) when is_tuple(node) do
      # For AST nodes like {:defmodule, metadata, children}, metadata is the 2nd element.
      metadata = elem(node, 1)
      Keyword.get(metadata, key)
    end
    def get(_node, _key), do: nil # Default case if not a tuple or metadata not found
  end

  # New describe blocks start here
  describe "ElixirAST.instrument_functions/3" do
    test "configures function instrumentation options" do
      config = ElixirAST.new()
      |> ElixirAST.instrument_functions(:all, log_entry_exit: true)
      
      expected_instr_opts = %{target_spec: :all, log_opts: true}
      assert config.function_instrumentation_opts == expected_instr_opts
    end
  end

  describe "ElixirAST.validate/1" do
    test "returns :ok for a default valid configuration" do
      assert ElixirAST.validate(ElixirAST.new()) == :ok
    end

    test "returns :ok for a configuration with valid :all target_spec" do
      config = ElixirAST.new() |> ElixirAST.instrument_functions(:all, log_entry_exit: true)
      assert ElixirAST.validate(config) == :ok
    end

    test "returns an error for an invalid target_spec" do
      # Simulate an invalid target spec by directly manipulating the struct,
      # as the public API might prevent creating this state directly.
      # This tests the validate function's robustness.
      raw_config = ElixirAST.new()
      # Ensure the builder module is correctly referenced here
      invalid_opts_config = %ElixirAST.Builder{raw_config | 
        function_instrumentation_opts: %{target_spec: :this_is_not_valid, log_opts: true}
      }
      assert ElixirAST.validate(invalid_opts_config) == {:error, :invalid_function_instrumentation_target_spec}
    end
  end

  describe "ElixirAST.parse_and_transform/2" do
    test "successfully parses and applies a simple transformation" do
      source = "defmodule MyMod do def my_func, do: :ok end"
      config = ElixirAST.new() |> ElixirAST.instrument_functions(:all, log_entry_exit: true)
      
      original_parse_result = ElixirAST.parse(source)
      assert {:ok, _original_ast} = original_parse_result
      
      transform_result = ElixirAST.parse_and_transform(config, source)
      assert {:ok, transformed_ast} = transform_result
      
      # Check if the dummy transformation was applied (metadata added to module)
      # Note: This relies on the simplified transform logic in Core.Transformer
      case transformed_ast do
        {:defmodule, meta, _} ->
          assert Keyword.get(meta, :transformed_for_logging) == true
        _ ->
          flunk "Transformed AST is not a defmodule as expected"
      end
    end

    test "returns parse error if parsing fails" do
      source = "defmodule MyMod do def my_func, do: end" # Invalid syntax
      config = ElixirAST.new() |> ElixirAST.instrument_functions(:all, log_entry_exit: true)
      assert {:error, _reason} = ElixirAST.parse_and_transform(config, source)
    end
  end
end
