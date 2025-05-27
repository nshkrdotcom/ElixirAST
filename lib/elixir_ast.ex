defmodule ElixirAST do
  @moduledoc """
  ElixirAST: Compile-Time AST Instrumentation Engine
  
  A clean, minimal library for programmatic AST instrumentation in Elixir.
  Focuses solely on compile-time code transformation with console output.
  
  ## Basic Usage
  
      config = ElixirAST.new()
      |> ElixirAST.instrument_functions(:all, log_entry_exit: [capture_args: true])
      |> ElixirAST.capture_variables_at_return([:result])
      
      {:ok, instrumented_ast} = ElixirAST.transform(config, ast)
  """

  alias ElixirAST.Builder
  # alias ElixirAST.Core # Will be needed later
  # alias ElixirAST.Output # Will be needed later

  # ============================================================================
  # Core Types
  # ============================================================================

  @typedoc "Abstract Syntax Tree node"
  @type ast_node() :: term()

  @typedoc "Unique identifier for an AST node after parsing"
  @type node_id() :: binary()

  @typedoc "Instrumentation configuration state, represented by the Builder struct"
  @type instrumentation_config() :: %Builder{}

  @typedoc "Result of an AST transformation"
  @type transformation_result() :: {:ok, ast_node()} | {:error, term()}

  @typedoc """
  Options for logging function entry/exit.
  - `capture_args`: `boolean()` - Whether to log function arguments on entry. Default `false`.
  - `capture_return`: `boolean()` - Whether to log function return value on exit. Default `false`.
  - `log_duration`: `boolean()` - Whether to log function execution duration. Default `false`.
  """
  @type log_entry_exit_opts() :: [
    capture_args: boolean(),
    capture_return: boolean(),
    log_duration: boolean()
  ]

  @typedoc """
  Options for capturing variables.
  - `at`: `:entry | :before_return | :on_error | {:line, pos_integer()}` - Where to capture. Default `:before_return`.
  """
  @type capture_variables_opts() :: [at: :entry | :before_return | :on_error | {:line, pos_integer()}]

  @typedoc """
  Options for tracking expressions.
  - `log_intermediate`: `boolean()` - Whether to log values before they are passed in a pipe. Default `false`.
  """
  @type track_expressions_opts() :: [log_intermediate: boolean()]

  @typedoc """
  Options for custom code injection.
  - `context_vars`: `[atom()]` - List of variables from the original scope to make available in the injected code.
  """
  @type injection_opts() :: [context_vars: [atom()]]

  # ============================================================================
  # Main API - Builder Pattern
  # ============================================================================

  @doc """
  Creates a new instrumentation configuration.
  
  ## Options
  - `output_target`: `atom()` - Where to send logs. Default `:console`.
  - `output_format`: `atom()` - Log format. Default `:simple`. See `ElixirAST.format/2`.
  
  ## Examples
      config = ElixirAST.new()
      config = ElixirAST.new(output_target: :console, output_format: :json)
  """
  @spec new(keyword()) :: instrumentation_config()
  def new(opts \ []) do
    Builder.new(opts)
  end

  @doc """
  Configures which functions to target for instrumentation.
  See `ElixirAST.Builder.instrument_functions/3` for detailed options.
  """
  @spec instrument_functions(instrumentation_config(), atom() | tuple(), keyword()) :: instrumentation_config()
  def instrument_functions(config, target_spec, instrumentation_opts \ []) do
    Builder.instrument_functions(config, target_spec, instrumentation_opts)
  end

  @doc """
  Configures local variable capture for targeted functions.
  See `ElixirAST.Builder.capture_variables/3` for detailed options.
  """
  @spec capture_variables(instrumentation_config(), [atom()] | :all, capture_variables_opts()) :: instrumentation_config()
  def capture_variables(config, variables, opts \ []) do
    Builder.capture_variables(config, variables, opts)
  end

  @doc """
  Configures tracking for specific expressions.
  See `ElixirAST.Builder.track_expressions/3` for detailed options.
  """
  @spec track_expressions(instrumentation_config(), [ast_node()], track_expressions_opts()) :: instrumentation_config()
  def track_expressions(config, expressions, opts \ []) do
    Builder.track_expressions(config, expressions, opts)
  end

  @doc """
  Injects custom quoted Elixir code at a specific line number.
  See `ElixirAST.Builder.inject_at_line/4` for detailed options.
  """
  @spec inject_at_line(instrumentation_config(), pos_integer(), ast_node(), injection_opts()) :: instrumentation_config()
  def inject_at_line(config, line_number, code, opts \ []) do
    Builder.inject_at_line(config, line_number, code, opts)
  end

  @doc """
  Injects custom quoted Elixir code immediately before function return statements.
  See `ElixirAST.Builder.inject_before_return/3` for detailed options.
  """
  @spec inject_before_return(instrumentation_config(), ast_node(), injection_opts()) :: instrumentation_config()
  def inject_before_return(config, code, opts \ []) do
    Builder.inject_before_return(config, code, opts)
  end

  @doc """
  Injects custom quoted Elixir code to be executed when an error is raised.
  See `ElixirAST.Builder.inject_on_error/3` for detailed options.
  """
  @spec inject_on_error(instrumentation_config(), ast_node(), injection_opts()) :: instrumentation_config()
  def inject_on_error(config, code, opts \ []) do
    Builder.inject_on_error(config, code, opts)
  end

  @doc """
  Configures instrumentation to target functions matching a predefined pattern.
  See `ElixirAST.Builder.target_pattern/2` for detailed options.
  """
  @spec target_pattern(instrumentation_config(), atom()) :: instrumentation_config()
  def target_pattern(config, pattern_name) do
    Builder.target_pattern(config, pattern_name)
  end

  @doc """
  Configures the output target for instrumentation logs.
  See `ElixirAST.Builder.output_to/2` for detailed options.
  """
  @spec output_to(instrumentation_config(), :console) :: instrumentation_config()
  def output_to(config, target) do
    Builder.output_to(config, target)
  end

  @doc """
  Configures the output format for console logs.
  See `ElixirAST.Builder.format/2` for detailed options.
  """
  @spec format(instrumentation_config(), :simple | :detailed | :json) :: instrumentation_config()
  def format(config, format_type) do
    Builder.format(config, format_type)
  end
  
  @doc """
  Validates the provided instrumentation configuration.
  See `ElixirAST.Builder.validate/1` for details.
  """
  @spec validate(instrumentation_config()) :: :ok | {:error, [term()]}
  def validate(config) do
    Builder.validate(config)
  end

  # ============================================================================
  # Transformation API
  # ============================================================================

  @doc """
  Transforms a given AST node based on the provided instrumentation configuration.
  This is the main function to apply instrumentation.
  """
  @spec transform(instrumentation_config(), ast_node()) :: transformation_result()
  def transform(_config, _ast) do
    # To be implemented: Call ElixirAST.Core.Transformer.transform(config, ast)
    {:error, :not_implemented_yet}
  end

  @doc """
  Parses Elixir source code into an AST and assigns unique node IDs.
  Node IDs are essential for some advanced instrumentation targeting.
  """
  @spec parse(binary()) :: {:ok, ast_node()} | {:error, term()}
  def parse(_source_code) when is_binary(_source_code) do
    # To be implemented: Call ElixirAST.Core.Parser.parse(source_code)
    {:error, :not_implemented_yet}
  end

  @doc """
  A convenience function that combines parsing source code and transforming the resulting AST.
  """
  @spec parse_and_transform(instrumentation_config(), binary()) :: transformation_result()
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

      # Propagate any error from parse or transform
      error -> error
    end
  end

  # ============================================================================
  # Utility Functions
  # ============================================================================

  @doc """
  Analyzes an AST to identify instrumentable components and patterns.
  Returns a map containing information like function definitions, detected patterns, etc.
  """
  @spec analyze(ast_node()) :: map()
  def analyze(_ast) do
    # To be implemented: Call ElixirAST.Core.Analyzer.analyze(ast)
    %{error: :not_implemented_yet}
  end

  @doc """
  Generates a preview of the instrumentation that would be applied
  based on the configuration, without actually transforming the AST.
  Returns a map detailing the instrumentation points and actions.
  """
  @spec preview(instrumentation_config(), ast_node()) :: map()
  def preview(_config, _ast) do
    # To be implemented: Call ElixirAST.Core.Transformer.preview(config, ast)
    %{error: :not_implemented_yet}
  end


  # ============================================================================
  # Convenience Functions
  # ============================================================================

  @doc """
  A quick way to instrument all functions in a source string for entry/exit logging
  and optionally capture specified variables. Output goes to the console.
  """
  @spec quick_instrument(binary(), keyword()) :: transformation_result()
  def quick_instrument(source_code, opts \ []) do
    log_entry_exit_opts = [
      capture_args: Keyword.get(opts, :log_args, true),
      capture_return: Keyword.get(opts, :log_return, true)
    ]

    config = new(output_format: Keyword.get(opts, :format, :simple)) # Calls ElixirAST.new/1
    |> instrument_functions(:all, log_entry_exit: log_entry_exit_opts) # Calls ElixirAST.instrument_functions/3
    |> capture_variables(Keyword.get(opts, :capture_vars, []), at: :before_return) # Calls ElixirAST.capture_variables/3
    |> output_to(:console) # Calls ElixirAST.output_to/2
    
    parse_and_transform(config, source_code) # Calls ElixirAST.parse_and_transform/2
  end

  @doc """
  Convenience function to instrument common GenServer callbacks.
  Logs entry/exit and captures relevant state variables by default.
  """
  @spec instrument_genserver(binary(), keyword()) :: transformation_result()
  def instrument_genserver(source_code, opts \ []) do
    default_genserver_vars = [:state, :new_state, :msg, :from, :reason, :value]
    vars_to_capture = Keyword.get(opts, :capture_vars, default_genserver_vars)
    log_entry_exit_opts = Keyword.get(opts, :log_entry_exit, [capture_args: true, capture_return: true, log_duration: true])

    config = new(output_format: Keyword.get(opts, :format, :detailed))
    |> target_pattern(:genserver_callbacks)
    |> instrument_functions(:all, log_entry_exit: log_entry_exit_opts)
    |> capture_variables(vars_to_capture, at: :before_return)
    |> capture_variables(vars_to_capture, at: :entry)
    |> output_to(:console)
    
    parse_and_transform(config, source_code)
  end

  @doc """
  Convenience function to instrument Phoenix controller actions.
  Logs entry/exit and captures `conn` and `params` variables by default.
  """
  @spec instrument_phoenix_controller(binary(), keyword()) :: transformation_result()
  def instrument_phoenix_controller(source_code, opts \ []) do
    vars_to_capture = Keyword.get(opts, :capture_vars, [:conn, :params])
    log_entry_exit_opts = Keyword.get(opts, :log_entry_exit, [capture_args: true, capture_return: true, log_duration: true])

    config = new(output_format: Keyword.get(opts, :format, :detailed))
    |> target_pattern(:phoenix_actions)
    |> instrument_functions(:all, log_entry_exit: log_entry_exit_opts)
    |> capture_variables(vars_to_capture, at: :entry)
    |> output_to(:console)
    
    parse_and_transform(config, source_code)
      error -> error # Pass through any error from parse or transform
    end
  end

  # New function
  def validate(config) do
    Builder.validate(config)
  end
end
