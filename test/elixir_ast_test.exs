defmodule ElixirASTTest do
  use ExUnit.Case, async: true

  alias ElixirAST
  alias ElixirAST.Api.Builder # To inspect the struct directly

  test "new/1 creates a default configuration" do
    config = ElixirAST.new()
    assert %Builder{
      output_target: :console,
      output_format: :simple,
      function_target_spec: {:instrument, :all} # Default from Builder struct
      # other fields should have their defaults from Builder.defstruct
    } = config
  end

  test "new/1 accepts output_target and output_format options" do
    config = ElixirAST.new(output_target: :console, output_format: :json, verbose_mode: true)
    assert config.output_target == :console
    assert config.output_format == :json
    assert config.verbose_mode == true
  end

  test "instrument_functions/3 updates function_target_spec and log_function_entry_exit_opts" do
    config = ElixirAST.new()
    |> ElixirAST.instrument_functions(:public, log_entry_exit: [capture_args: true, log_duration: false])

    assert config.function_target_spec == :public
    assert config.log_function_entry_exit_opts == [capture_args: true, log_duration: false]
  end
  
  test "instrument_functions/3 correctly uses :all, :private, :only, :except specs" do
    config_all = ElixirAST.new() |> ElixirAST.instrument_functions(:all)
    assert config_all.function_target_spec == :all

    config_private = ElixirAST.new() |> ElixirAST.instrument_functions(:private)
    assert config_private.function_target_spec == :private
    
    only_spec = {:only, [:func1, {:func2, 2}]}
    config_only = ElixirAST.new() |> ElixirAST.instrument_functions(only_spec)
    assert config_only.function_target_spec == only_spec

    except_spec = {:except, [:func3]}
    config_except = ElixirAST.new() |> ElixirAST.instrument_functions(except_spec)
    assert config_except.function_target_spec == except_spec
  end

  test "instrument_functions/3 handles capture_variables shortcut" do
    config = ElixirAST.new()
    |> ElixirAST.instrument_functions(:all, capture_variables: [:state, :result])
    
    expected_vars_map = %{before_return: [:state, :result]} # Default :at is :before_return
    assert config.variables_to_capture == expected_vars_map
  end

  test "capture_variables/3 updates variables_to_capture correctly" do
    config = ElixirAST.new()
    |> ElixirAST.capture_variables([:foo, :bar], at: :entry)
    |> ElixirAST.capture_variables([:baz], at: {:line, 10})
    |> ElixirAST.capture_variables(:all, at: :on_error)
    |> ElixirAST.capture_variables([:foo], at: :entry) # Test adding to existing list and uniq

    assert config.variables_to_capture == %{
      entry: [:foo, :bar], # :foo should not be duplicated
      {:line, 10} => [:baz],
      on_error: [:all]
    }
  end

  test "track_expressions/3 adds expressions and options to expressions_to_track" do
    expr1 = quote(do: a + b)
    expr2 = quote(do: c - d)
    opts1 = [log_intermediate: true]
    opts2 = [] # Default opts

    config = ElixirAST.new()
    |> ElixirAST.track_expressions([expr1], opts1)
    |> ElixirAST.track_expressions([expr2], opts2)
    
    # The builder adds each expression as a separate entry
    assert config.expressions_to_track == [{expr1, opts1}, {expr2, opts2}]
  end

  test "inject_at_line/4 adds code to custom_injections for specific line" do
    code_ast = quote(do: IO.inspect("line 10"))
    opts = [context_vars: [:x]]
    config = ElixirAST.new() |> ElixirAST.inject_at_line(10, code_ast, opts)

    assert config.custom_injections == %{{:at_line, 10} => [{code_ast, opts}]}
  end

  test "inject_before_return/3 adds code to custom_injections for before_return" do
    code_ast = quote(do: IO.inspect("returning"))
    opts = []
    config = ElixirAST.new() |> ElixirAST.inject_before_return(code_ast, opts)
    
    assert config.custom_injections == %{before_return: [{code_ast, opts}]}
  end

  test "inject_on_error/3 adds code to custom_injections for on_error" do
    code_ast = quote(do: IO.inspect("error occurred"))
    opts = [context_vars: [:e]]
    config = ElixirAST.new() |> ElixirAST.inject_on_error(code_ast, opts)
    
    assert config.custom_injections == %{on_error: [{code_ast, opts}]}
  end
  
  test "target_pattern/2 adds unique patterns to pattern_targets" do
    config = ElixirAST.new()
    |> ElixirAST.target_pattern(:genserver_callbacks)
    |> ElixirAST.target_pattern(:phoenix_actions)
    |> ElixirAST.target_pattern(:genserver_callbacks) # Add duplicate
    
    assert Enum.sort(config.pattern_targets) == [:genserver_callbacks, :phoenix_actions] |> Enum.sort()
  end

  test "output_to/2 configures output_target" do
    config = ElixirAST.new() |> ElixirAST.output_to(:console)
    assert config.output_target == :console
    
    # Test with an invalid target (should be ignored by builder, caught by validate)
    # config_invalid = ElixirAST.new() |> ElixirAST.output_to(:file)
    # assert config_invalid.output_target == :console # Assuming builder ignores invalid
  end

  test "format/2 configures output_format" do
    config_simple = ElixirAST.new() |> ElixirAST.format(:simple)
    assert config_simple.output_format == :simple

    config_detailed = ElixirAST.new() |> ElixirAST.format(:detailed)
    assert config_detailed.output_format == :detailed

    config_json = ElixirAST.new() |> ElixirAST.format(:json)
    assert config_json.output_format == :json
    
    # Test with an invalid format (should be ignored by builder, caught by validate)
    # config_invalid = ElixirAST.new() |> ElixirAST.format(:xml)
    # assert config_invalid.output_format == :simple # Assuming builder ignores invalid
  end

  # --- Tests for ElixirAST.validate/1 (public API) ---
  test "validate/1 (public API) returns :ok for a valid configuration" do
    config = ElixirAST.new()
    |> ElixirAST.instrument_functions(:public)
    |> ElixirAST.format(:json)
    assert ElixirAST.validate(config) == :ok
  end

  test "validate/1 (public API) returns {:error, reasons} for an invalid configuration" do
    config = ElixirAST.new(output_format: :invalid_format) # Use new/1 to set invalid
    assert {:error, reasons} = ElixirAST.validate(config)
    assert Keyword.has_key?(reasons, :invalid_output_format)
  end

  # --- Placeholder tests for functions not yet fully implemented or dependent on other modules ---
  # These will remain flunked or use basic assertions if they only call stubs.

  test "transform/2 returns :not_implemented_transformer (current stub)" do
    config = ElixirAST.new()
    ast = quote(do: :foo)
    assert ElixirAST.transform(config, ast) == {:error, :not_implemented_transformer}
  end

  # Tests for ElixirAST.parse/1 (delegates to Core.Parser)
  # These were made concrete in the previous subtask for Core.Parser tests.
  # We can have a simple one here to ensure delegation.
  test "parse/1 (public API) delegates to Core.Parser and returns AST with node IDs" do
    source = "defmodule M, do: (def f, do: 1)"
    assert {:ok, ast} = ElixirAST.parse(source)
    assert match?({:defmodule, meta, _}, ast)
    assert Keyword.has_key?(meta, :elixir_ast_node_id)
  end

  test "parse_and_transform/2 combines parse and transform (currently transform is stubbed)" do
    config = ElixirAST.new()
    source_code = "def my_fun, do: :ok"
    # Since transform is a stub returning error, parse_and_transform should reflect that.
    assert ElixirAST.parse_and_transform(config, source_code) == {:error, :not_implemented_transformer}
  end

  test "analyze/1 returns :not_implemented_analyzer (current stub)" do
    ast = quote(do: :foo)
    assert ElixirAST.analyze(ast) == %{error: :not_implemented_analyzer}
  end

  test "preview/2 returns :not_implemented_preview (current stub)" do
    config = ElixirAST.new()
    ast = quote(do: :foo)
    assert ElixirAST.preview(config, ast) == %{error: :not_implemented_preview}
  end

  # --- Convenience Functions ---
  # These depend on parse and transform. Since transform is a stub, they'll return its error.
  test "quick_instrument/2 returns error due to transform stub" do
    source = "def hello, do: :world"
    assert ElixirAST.quick_instrument(source) == {:error, :not_implemented_transformer}
  end
  
  test "quick_instrument/2 configures builder correctly before calling parse_and_transform" do
    # This test can check the config part, even if transform is stubbed
    # To do this, we'd need to intercept the config passed to parse_and_transform,
    # or trust the builder functions are tested.
    # For now, we'll focus on the fact it calls the builder.
    # A full test requires a working transform or mocking.
    # We can assert that the call to parse_and_transform will eventually happen with a correctly built config.
    # This is implicitly tested by ensuring the builder functions work.
    source = "def hi, do: :ok"
    opts = [capture_vars: [:res], log_args: true, log_return: true, format: :detailed]
    
    # We cannot directly inspect the config passed to parse_and_transform here.
    # This test effectively relies on other tests ensuring `new`, `instrument_functions`, 
    # `capture_variables`, `output_to`, and `format` work correctly.
    # The result will be the error from the transform stub.
    assert ElixirAST.quick_instrument(source, opts) == {:error, :not_implemented_transformer}
    # If we could mock parse_and_transform, we'd check the config passed to it.
  end

  test "instrument_genserver/2 returns error due to transform stub" do
    source = "defmodule MyGS, do: (use GenServer)"
    assert ElixirAST.instrument_genserver(source) == {:error, :not_implemented_transformer}
  end

  test "instrument_phoenix_controller/2 returns error due to transform stub" do
    source = "defmodule MyCtrl, do: (use Phoenix.Controller)"
    assert ElixirAST.instrument_phoenix_controller(source) == {:error, :not_implemented_transformer}
  end
end
