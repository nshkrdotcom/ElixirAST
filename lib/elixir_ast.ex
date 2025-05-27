defmodule ElixirAST do
  @moduledoc """
  ElixirAST: Compile-Time AST Instrumentation Engine


  A clean, minimal library for programmatic AST instrumentation in Elixir.
  Focuses solely on compile-time code transformation with console output.

  ## Basic Usage

      config = ElixirAST.new()
      |> ElixirAST.instrument_functions(:all, log_entry_exit: [capture_args: true])
      |> ElixirAST.capture_variables([:result])

      # Assuming 'ast' is a quoted Elixir AST
      # {:ok, instrumented_ast} = ElixirAST.transform(config, ast)

  """

  alias ElixirAST.Api.Builder # Using the namespaced Builder
  alias ElixirAST.Core # For Parser, Transformer, Analyzer - to be used later

  # ============================================================================
  # Core Types (as per PRD, Builder type points to our namespaced one)
  # ============================================================================

  @typedoc "Abstract Syntax Tree node"
  @type ast_node() :: term()

  @typedoc "Unique identifier for an AST node after parsing"
  @type node_id() :: binary()

  @typedoc "Instrumentation configuration state"
  @type instrumentation_config() :: %Builder{} # Points to ElixirAST.Api.Builder

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
=======
  
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


  @doc """
  Configures which functions to target for instrumentation.

  ## `target_spec` Options
  - `:all` - Instrument all functions (`def` and `defp`).
  - `:public` - Only public functions (`def`).
  - `:private` - Only private functions (`defp`).
  - `{:only, [atom() | {atom(), pos_integer()}]}` - Instrument only specified functions.
    Functions can be atoms (name only) or `{name, arity}` tuples.
  - `{:except, [atom() | {atom(), pos_integer()}]}` - Instrument all functions except specified ones.

  ## `instrumentation_opts` Options
  - `log_entry_exit`: `boolean() | log_entry_exit_opts()` - Log function entry and exit.
    If `true`, uses default logging. Provide a keyword list for custom options. Default `false`.
  - `capture_variables`: `[atom()] | :all | capture_variables_opts()` - Capture local variables.
    Provide a list of variable names, `:all`, or a keyword list for options. Default `[]`.

  ## Examples
      # Log entry/exit for all functions
      ElixirAST.new() |> ElixirAST.instrument_functions(:all, log_entry_exit: true)

      # Log entry/exit with args/return for public functions
      ElixirAST.new() |> ElixirAST.instrument_functions(:public, log_entry_exit: [capture_args: true, capture_return: true])

      # Instrument only specific functions and capture one variable
      ElixirAST.new()
      |> ElixirAST.instrument_functions({:only, [:handle_call, {:handle_cast, 2}]}, capture_variables: [:state])
  """
  @spec instrument_functions(instrumentation_config(), atom() | tuple(), keyword()) :: instrumentation_config()
  def instrument_functions(config, target_spec, instrumentation_opts \\ []) do
    Builder.do_instrument_functions(config, target_spec, instrumentation_opts)
  end

  @doc """
  Configures local variable capture for targeted functions.
  Variables are captured and logged.

  ## `variables`
  - `[atom()]`: A list of variable names (as atoms) to capture.
  - `:all`: Capture all local variables available in scope.

  ## `opts` (`capture_variables_opts()`)
  - `:at`: Specifies when/where to capture variables.
    - `:entry`: At the beginning of the function.
    - `:before_return`: Just before the function returns (default).
    - `:on_error`: If an error is raised within the function.
    - `{:line, number}`: After a specific line number.

  ## Examples
      # Capture :input and :result variables before function returns
      ElixirAST.new() |> ElixirAST.capture_variables([:input, :result])

      # Capture all variables at function entry
      ElixirAST.new() |> ElixirAST.capture_variables(:all, at: :entry)

      # Capture variable :x after line 10
      ElixirAST.new() |> ElixirAST.capture_variables([:x], at: {:line, 10})
  """
  @spec capture_variables(instrumentation_config(), [atom()] | :all, capture_variables_opts()) :: instrumentation_config()
  def capture_variables(config, variables, opts \\ []) do
    Builder.do_capture_variables(config, variables, opts)
  end

  @doc """
  Configures tracking for specific expressions.
  The result of each specified expression will be logged.

  ## `expressions`
  - A list of quoted Elixir expressions to track.

  ## `opts` (`track_expressions_opts()`)
  - `log_intermediate`: If `true`, for pipe operations (`|>`), logs the value before it's passed
    to the next function in the pipe. Default `false`.

  ## Examples
      ElixirAST.new()
      |> ElixirAST.track_expressions([
        quote(do: user |> validate_user() |> save_user()), # Tracks final result of pipe
        quote(do: complex_calculation(x, y) * discount_rate) # Tracks result of multiplication
      ])

      # Log intermediate results in a pipe
      ElixirAST.new()
      |> ElixirAST.track_expressions([quote(do: data |> process1() |> process2())], log_intermediate: true)
  """
  @spec track_expressions(instrumentation_config(), [ast_node()], track_expressions_opts()) :: instrumentation_config()
  def track_expressions(config, expressions, opts \\ []) do
    Builder.do_track_expressions(config, expressions, opts)
  end

  @doc """
  Injects custom quoted Elixir code at a specific line number.
  The injected code is executed *after* the original code at that line.

  ## `opts` (`injection_opts()`)
  - `context_vars`: A list of variable names (atoms) from the original code's scope
    that should be made available to the injected code. These variables will be bound
    with their runtime values when the injected code executes.

  ## Examples
      ElixirAST.new()
      |> ElixirAST.inject_at_line(42, quote(do: IO.puts("Debug: Checkpoint at line 42")))

      # Inject code that uses variables from the original scope
      ElixirAST.new()
      |> ElixirAST.inject_at_line(10,
           quote(do: ElixirAST.Output.Console.log_value("User ID at line 10", user_id)),
           context_vars: [:user_id]
         )
  """
  @spec inject_at_line(instrumentation_config(), pos_integer(), ast_node(), injection_opts()) :: instrumentation_config()
  def inject_at_line(config, line_number, code, opts \\ []) do
    Builder.do_inject_at_line(config, line_number, code, opts)
  end

  @doc """
  Injects custom quoted Elixir code immediately before function return statements.
  The injected code has access to a `result` variable containing the function's return value.

  ## `opts` (`injection_opts()`)
  - `context_vars`: A list of variable names (atoms) from the original function's scope
    to make available to the injected code.

  ## Examples
      ElixirAST.new()
      |> ElixirAST.inject_before_return(quote(do: ElixirAST.Output.Console.log_value("Function result", result)))

      ElixirAST.new()
      |> ElixirAST.inject_before_return(
           quote(do: ElixirAST.Output.Console.log_value("Final state before return", %{result: result, state: current_state})),
           context_vars: [:current_state] # 'result' is implicitly available
         )
  """
  @spec inject_before_return(instrumentation_config(), ast_node(), injection_opts()) :: instrumentation_config()
  def inject_before_return(config, code, opts \\ []) do
    Builder.do_inject_before_return(config, code, opts)
  end

  @doc """
  Injects custom quoted Elixir code to be executed when an error is raised within a targeted function.
  The injected code has access to `error` (the kind of error) and `reason` (the error reason/message),
  and `stacktrace`.

  ## `opts` (`injection_opts()`)
  - `context_vars`: A list of variable names (atoms) from the original function's scope
    to make available to the injected code.

  ## Examples
      ElixirAST.new()
      |> ElixirAST.inject_on_error(
           quote(do: ElixirAST.Output.Console.log_error("Error caught", error, reason, stacktrace))
         )
  """
  @spec inject_on_error(instrumentation_config(), ast_node(), injection_opts()) :: instrumentation_config()
  def inject_on_error(config, code, opts \\ []) do
    Builder.do_inject_on_error(config, code, opts)
  end

  @doc """
  Configures instrumentation to target functions matching a predefined pattern.
  This applies subsequent instrumentation rules (like `instrument_functions`) only to
  functions matching the pattern.

  ## Built-in Patterns
  - `:genserver_callbacks`: Targets `init/1`, `handle_call/3`, `handle_cast/2`, `handle_info/2`, `terminate/2`, `code_change/3`.
  - `:phoenix_actions`: Targets common Phoenix controller action names (e.g., `index/2`, `show/2`, `create/2`).
  - `:phoenix_live_view_callbacks`: Targets `mount/3`, `handle_event/3`, `handle_info/2`, `render/1`.
  - `:public_functions`: Targets all `def` functions.
  - `:private_functions`: Targets all `defp` functions.
  - `:recursive_functions`: Targets functions that call themselves (simple direct recursion).

  ## Examples
      # Instrument all GenServer callbacks
      ElixirAST.new()
      |> ElixirAST.target_pattern(:genserver_callbacks)
      |> ElixirAST.instrument_functions(:all, log_entry_exit: [capture_args: true, capture_state_before: true])

      # Capture variables only in Phoenix controller actions
      ElixirAST.new()
      |> ElixirAST.target_pattern(:phoenix_actions)
      |> ElixirAST.capture_variables([:conn, :params], at: :entry)
  """
  @spec target_pattern(instrumentation_config(), atom()) :: instrumentation_config()
  def target_pattern(config, pattern_name) do
    Builder.do_target_pattern(config, pattern_name)
  end

  @doc """
  Configures the output target for instrumentation logs.
  Currently, only `:console` is supported for the MVP.

  ## Examples
      ElixirAST.new() |> ElixirAST.output_to(:console)
  """
  @spec output_to(instrumentation_config(), :console) :: instrumentation_config()
  def output_to(config, target) do
    Builder.do_output_to(config, target)
  end

  @doc """
  Configures the output format for console logs.

  ## Format Types
  - `:simple`: Basic, human-readable text output. (Default)
    Example: `[ENTRY] MyModule.my_func/1 ARGS: [42]`
  - `:detailed`: More verbose output, including timestamps, PIDs.
    Example: `[2024-05-27T10:00:00.123Z <0.123.0> ENTRY] MyModule.my_func/1 ARGS: [42]`
  - `:json`: Machine-readable JSON output.
    Example: `{"timestamp": "...", "pid": "...", "type": "entry", "module": "MyModule", ...}`

  ## Examples
      ElixirAST.new() |> ElixirAST.format(:json)
  """
  @spec format(instrumentation_config(), :simple | :detailed | :json) :: instrumentation_config()
  def format(config, format_type) do
    Builder.do_format(config, format_type)
  end

  @doc """
  Validates the provided instrumentation configuration.
  Returns `:ok` if the configuration is valid, or `{:error, reasons}` otherwise.

  ## Examples
      config = ElixirAST.new() # |> ElixirAST.instrument_functions(:invalid_target_spec) # Example of invalid
      case ElixirAST.validate(config) do
        :ok -> IO.puts("Config is valid.")
        {:error, reasons} -> IO.inspect(reasons, label: "Invalid config")
      end
  """
  @spec validate(instrumentation_config()) :: :ok | {:error, [term()]}
  def validate(config) do
    Builder.validate(config)
  end

  # ============================================================================
  # Transformation API (Stubs for now - to be implemented in later subtasks)
  # ============================================================================

  @doc """
  Transforms a given AST node based on the provided instrumentation configuration.
  This is the main function to apply instrumentation.

  ## Examples
      # {:ok, ast} = ElixirAST.parse(source_code) # Assuming parse is implemented
      # config = ElixirAST.new() |> ElixirAST.instrument_functions(:all)
      # {:ok, instrumented_ast} = ElixirAST.transform(config, ast)
  """
  @spec transform(instrumentation_config(), ast_node()) :: transformation_result()
  def transform(_config, _ast) do
    # To be implemented: Calls Core.Transformer.transform(config, ast)
    {:error, :not_implemented_transformer}
  end

  @doc """
  Parses Elixir source code into an AST and assigns unique node IDs.
  Node IDs are essential for some advanced instrumentation targeting.

  ## Examples
      source = "def hello(name), do: IO.puts('Hello ' <> name)"
      {:ok, ast_with_node_ids} = ElixirAST.parse(source)
  """
  @spec parse(binary()) :: {:ok, ast_node()} | {:error, term()}
  def parse(source_code) when is_binary(source_code) do
    Core.Parser.parse(source_code) # Delegates to the already implemented Parser
  end

  @doc """
  A convenience function that combines parsing source code and transforming the resulting AST.

  ## Examples
      # config = ElixirAST.new() |> ElixirAST.instrument_functions(:all)
      # source_code = "def my_fun, do: :ok"
      # {:ok, instrumented_ast} = ElixirAST.parse_and_transform(config, source_code)
  """
  @spec parse_and_transform(instrumentation_config(), binary()) :: transformation_result()
  def parse_and_transform(config, source_code) do
    with {:ok, ast} <- parse(source_code),
         {:ok, instrumented_ast} <- transform(config, ast) do # transform is currently a stub
      {:ok, instrumented_ast}
    else
      {:error, reason} -> {:error, reason} # Handles errors from parse or transform
      error_tuple -> error_tuple # Handles other error formats

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

  # Utility Functions (Stubs for now)

  # Utility Functions

  # ============================================================================

  @doc """
  Analyzes an AST to identify instrumentable components and patterns.
  Returns a map containing information like function definitions, detected patterns, etc.

  This can be useful for deciding how to configure instrumentation.

  ## Examples
      # {:ok, ast} = ElixirAST.parse(source_code)
      # analysis_report = ElixirAST.analyze(ast)
      # %{
      #   functions: [%{name: :hello, arity: 1, line: 1, type: :def}],
      #   patterns_detected: [:simple_function],
      #   node_count: 15, # Example node count
      #   complexity_estimate: :low
      # }
  """
  @spec analyze(ast_node()) :: map()
  def analyze(_ast) do
    # To be implemented: Calls Core.Analyzer.analyze(ast)
    %{error: :not_implemented_analyzer}

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


  ## Examples
      # config = ElixirAST.new() |> ElixirAST.instrument_functions(:all)
      # {:ok, ast} = ElixirAST.parse(source_code)
      # instrumentation_preview = ElixirAST.preview(config, ast)
      # %{
      #   target_functions: [...],
      #   injections: [%{type: :log_entry, target: {MyModule, :my_func, 1}}, ...],
      #   variable_captures: [...]
      # }
  """
  @spec preview(instrumentation_config(), ast_node()) :: map()
  def preview(_config, _ast) do
    # To be implemented: Calls Core.Transformer.preview(config, ast)
    %{error: :not_implemented_preview}

  """
  @spec preview(instrumentation_config(), ast_node()) :: map()
  def preview(_config, _ast) do
    # To be implemented: Call ElixirAST.Core.Transformer.preview(config, ast)
    %{error: :not_implemented_yet}

  end


  # ============================================================================

  # Convenience Functions (Stubs for now, as they depend on full builder logic)



  @doc """
  A quick way to instrument all functions in a source string for entry/exit logging
  and optionally capture specified variables. Output goes to the console.


  ## `opts`
  - `capture_vars`: `[atom()] | :all` - Variables to capture. Default `[]`.
  - `log_args`: `boolean()` - Log function arguments. Default `true`.
  - `log_return`: `boolean()` - Log function return value. Default `true`.

  ## Examples
      # Instrument all functions with entry/exit logging
      # {:ok, ast} = ElixirAST.quick_instrument(source_code)

      # Instrument and capture specific variables
      # {:ok, ast} = ElixirAST.quick_instrument(source_code, capture_vars: [:result, :user_state])
  """
  @spec quick_instrument(binary(), keyword()) :: transformation_result()
  def quick_instrument(source_code, opts \\ []) do

  """
  @spec quick_instrument(binary(), keyword()) :: transformation_result()
  def quick_instrument(source_code, opts \ []) do

    log_entry_exit_opts = [
      capture_args: Keyword.get(opts, :log_args, true),
      capture_return: Keyword.get(opts, :log_return, true)
    ]


    # Note: Keyword.get/3 on opts for :capture_vars needs a default for capture_variables/3
    vars_to_capture = Keyword.get(opts, :capture_vars, []) # Default to empty list

    config = new(output_format: Keyword.get(opts, :format, :simple))
    |> instrument_functions(:all, log_entry_exit: log_entry_exit_opts)
    |> capture_variables(vars_to_capture, at: :before_return) # Explicitly use the builder function
    |> output_to(:console)

    parse_and_transform(config, source_code)
  end

  @doc """
  Convenience function to instrument common GenServer callbacks (`init/1`, `handle_call/3`, etc.).
  Logs entry/exit and captures `state` and `new_state` variables by default.

  ## `opts`
  - `capture_vars`: `[atom()] | :all` - Additional variables to capture. `:state` and `:new_state` are often relevant. Default `[:state, :new_state]`.
  - Other options compatible with `instrument_functions/3`.

  ## Examples
      # {:ok, ast} = ElixirAST.instrument_genserver(genserver_source_code)

      # {:ok, ast} = ElixirAST.instrument_genserver(genserver_source_code, capture_vars: [:state, :msg, :from])
  """
  @spec instrument_genserver(binary(), keyword()) :: transformation_result()
  def instrument_genserver(source_code, opts \\ []) do
    default_genserver_vars = [:state, :new_state, :msg, :from, :reason, :value]
    vars_to_capture = Keyword.get(opts, :capture_vars, default_genserver_vars)


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

  ## `opts`
  - `capture_vars`: `[atom()] | :all` - Additional variables to capture. Default `[:conn, :params]`.
  - Other options compatible with `instrument_functions/3`.

  ## Examples
      # {:ok, ast} = ElixirAST.instrument_phoenix_controller(controller_source_code)
  """
  @spec instrument_phoenix_controller(binary(), keyword()) :: transformation_result()
  def instrument_phoenix_controller(source_code, opts \\ []) do

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
