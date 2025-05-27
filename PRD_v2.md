Okay, I will complete the Product Requirements Document (PRD) for the ElixirAST MVP.

```# ElixirAST: MVP Product Requirements Document
**Compile-Time AST Instrumentation Engine for Elixir**

## 1. Product Vision & Goals

### Vision Statement
ElixirAST is a **minimal, focused library** that provides clean, programmatic APIs for compile-time AST instrumentation in Elixir. It extracts the core innovation from ElixirScope—compile-time code transformation—into a reusable, standalone component.

### Primary Goals
1. **Simplicity**: Single-purpose library focused only on AST instrumentation
2. **Clean API**: Intuitive, composable interfaces for code transformation
3. **Zero Runtime Overhead (for instrumentation logic itself)**: All transformation work happens at compile-time. Injected code (e.g., logging) will have its own runtime characteristics.
4. **Developer Experience**: Console-based output for immediate feedback and understanding of instrumentation.
5. **Reusability**: Designed as a foundational library for building more complex debugging, observability, or analysis tools.

### Non-Goals (Explicitly Out of Scope)
- ❌ Event storage or persistence (events are logged to console)
- ❌ Runtime event collection infrastructure (beyond console logging)
- ❌ AI integration or analysis
- ❌ UI or visualization components
- ❌ Distributed tracing
- ❌ Production-ready observability (the library itself is a tool, not a full observability solution)
- ❌ Automatic instrumentation plan generation (configuration is manual via API)

## 2. Target Users & Use Cases

### Primary Users
- **Library Authors**: Building debugging, tracing, or observability tools.
- **Framework Developers**: Adding opt-in instrumentation capabilities to frameworks like Phoenix, LiveView, etc.
- **Elixir Developers**: Gaining deeper understanding of their code execution patterns for debugging or learning.
- **Tool Builders**: Creating custom static analysis tools, code coverage tools, or specialized linters.

### Key Use Cases
1. **Function Entry/Exit Logging**: Automatically log when functions are called and when they return, including arguments and results.
2. **Variable State Capture**: Snapshot and log the values of local variables at specific points within functions (e.g., before/after key operations, at return).
3. **Expression Evaluation Tracking**: Log the results of specific intermediate expressions within a function.
4. **Pattern Match Monitoring**: Track the success or failure of pattern matches and log the values involved.
5. **Custom Instrumentation Points**: Insert arbitrary Elixir code (e.g., custom logging, metrics reporting stubs) at various points in the AST (before/after function calls, specific lines).
6. **Educational Tool**: Help developers visualize Elixir's execution flow and understand metaprogramming.

## 3. MVP Feature Requirements

### Core Features

#### ✅ **F1: AST Parser & Node Identification**
- Parse Elixir source code string into an AST.
- Assign unique, stable, and deterministic node IDs to relevant AST nodes (modules, functions, expressions).
- Provide utilities to traverse the AST and identify specific node types or patterns.
- Handle all major Elixir constructs: `defmodule`, `def`, `defp`, `defmacro`, `defmacrop`, `case`, `cond`, `if`, `unless`, `try`, `receive`, `fn`, pipe operator (`|>`), assignments (`=`), comprehensions (`for`).

#### ✅ **F2: Instrumentation API (Builder Pattern)**
- Provide a clean, composable, and fluent API for defining instrumentation configurations.
- Support targeting all functions, public/private functions, or specific functions by name/arity.
- Support targeting common Elixir patterns (e.g., GenServer callbacks, Phoenix controller actions) through predefined or custom pattern matchers.
- Allow configuration for different instrumentation types:
    - Function entry/exit logging (including arguments and return values).
    - Local variable capture (at function start, before return, or at specific lines/nodes).
    - Expression value tracking.
    - Custom code injection at various points (before/after function body, before return, on error, specific lines).
- Configuration should be declarative and easy to read.

#### ✅ **F3: AST Transformation Engine**
- Take an AST and an instrumentation configuration as input.
- Inject the specified instrumentation code (primarily console logging calls for MVP) into the AST.
- Ensure the original code semantics and behavior are preserved after transformation.
- Handle edge cases gracefully, such as guards, multi-clause functions, macros, and complex pattern matching.
- Generate efficient and readable instrumentation code.
- Provide clear error reporting if transformation fails.

#### ✅ **F4: Console Output System**
- Provide a runtime component (called by instrumented code) to log information to the console.
- Support structured logging to the console, clearly indicating the source of the log (module, function, line).
- Offer configurable output formats:
    - `:simple`: Basic textual output.
    - `:detailed`: More verbose output, including timestamps, PIDs.
    - `:json`: Machine-readable JSON output.
- Use color-coding for console output to improve readability (e.g., green for entry, blue for exit, yellow for variables).
- Include optional performance timing information for instrumented function calls (duration).

#### ✅ **F5: Test Harness & Examples**
- A comprehensive test suite demonstrating all API features and transformation capabilities.
- Example Elixir scripts showcasing common instrumentation patterns and use cases.
- Clear documentation on how to use the library and interpret its output.
- Basic performance benchmarks for core parsing and transformation operations.
- Examples of how to integrate `ElixirAST` into a `Mix.Task` or a compile-time hook (though full Mix task is out of scope for MVP library itself).

### API Design Requirements

#### **R1: Declarative Configuration (Builder Pattern)**
The API should allow users to declaratively build an instrumentation configuration.
```elixir
instrumentation_config = ElixirAST.new()
|> ElixirAST.instrument_functions(:all) # Target all functions
|> ElixirAST.log_function_entry_exit(capture_args: true, capture_return: true)
|> ElixirAST.capture_variables_at_return([:result, :input_params]) # Capture specific vars before return
|> ElixirAST.output_to(:console, format: :detailed) # Specify output
```

#### **R2: Pattern-Based Targeting**
The API should support targeting common Elixir patterns for instrumentation.
```elixir
# Example: Instrument all GenServer callbacks
genserver_instrumentation = ElixirAST.new()
|> ElixirAST.target_pattern(:genserver_callbacks) # Predefined pattern
|> ElixirAST.log_function_entry_exit(capture_args: true, capture_state_before: true, capture_state_after: true)
|> ElixirAST.output_to(:console, format: :structured)
```

#### **R3: Custom Code Injection**
The API should allow injecting custom Elixir code at various AST points.
```elixir
custom_instrumentation = ElixirAST.new()
|> ElixirAST.target_functions({MyModule, :critical_function, 2})
|> ElixirAST.inject_at_line(42, quote do: IO.puts("Debug: Checkpoint Alpha reached at line 42") end)
|> ElixirAST.inject_before_return(quote do: ElixirAST.Output.Console.log_value("Return value for critical_function", result) end)
|> ElixirAST.inject_on_error(quote do: ElixirAST.Output.Console.log_error("Error in critical_function", error, stacktrace) end)
```

## 4. Technical Architecture

### Core Components

```mermaid
graph TB
    subgraph "Input Layer"
        SOURCE[Source Code (String)]
        AST_INPUT[Raw AST (Optional)]
        CONFIG_BUILDER[Instrumentation Config (via Builder API)]
    end
    
    subgraph "ElixirAST Core Engine"
        PARSER[Core.Parser (Source -> AST, Node ID Assignment)]
        ANALYZER[Core.Analyzer (Pattern Detection, Target Identification)]
        TRANSFORMER[Core.Transformer (AST Traversal & Modification)]
        INJECTOR[Core.Injector (Instrumentation Code Generation)]
    end
    
    subgraph "Output & Runtime Support"
        INSTRUMENTED_AST[Instrumented AST (Output of Transform)]
        CONSOLE_LOGGER[Output.Console (Runtime Logging Utilities)]
    end
    
    subgraph "API Layer (ElixirAST Module)"
        PUBLIC_API[ElixirAST Public Functions]
        BUILDER_MODULE[ElixirAST.Builder (Fluent API State)]
        PATTERN_MODULE[ElixirAST.Patterns (Pattern Definitions)]
    end
    
    %% Input flow
    SOURCE --> PARSER
    AST_INPUT --> ANALYZER
    CONFIG_BUILDER --> ANALYZER
    
    %% Core processing
    PARSER --> ANALYZER
    ANALYZER --> TRANSFORMER
    TRANSFORMER --> INJECTOR
    
    %% API integration
    PUBLIC_API --> BUILDER_MODULE
    BUILDER_MODULE --> PATTERN_MODULE
    BUILDER_MODULE --> CONFIG_BUILDER
    
    %% Output
    INJECTOR --> INSTRUMENTED_AST
    
    %% Runtime (conceptual link for instrumented code)
    INSTRUMENTED_AST -.->|Instrumented code calls| CONSOLE_LOGGER
    
    %% Styling
    classDef inputClass fill:#e1f5fe,stroke:#333,stroke-width:2px
    classDef coreClass fill:#c8e6c9,stroke:#333,stroke-width:2px
    classDef outputClass fill:#fff3e0,stroke:#333,stroke-width:2px
    classDef apiClass fill:#f3e5f5,stroke:#333,stroke-width:2px
    
    class SOURCE,AST_INPUT,CONFIG_BUILDER inputClass
    class PARSER,ANALYZER,TRANSFORMER,INJECTOR coreClass
    class INSTRUMENTED_AST,CONSOLE_LOGGER outputClass
    class PUBLIC_API,BUILDER_MODULE,PATTERN_MODULE apiClass
```

### Module Structure

```
lib/elixir_ast/
├── core/
│   ├── parser.ex              # AST parsing, node ID assignment
│   ├── analyzer.ex            # Code pattern analysis, target identification
│   ├── transformer.ex         # AST transformation engine, traversal
│   └── injector.ex            # Instrumentation code generation & injection utilities
├── api/
│   ├── builder.ex             # Fluent API builder struct and functions
│   ├── patterns.ex            # Predefined pattern matchers (e.g., GenServer, Phoenix)
│   └── config_structs.ex      # Internal structs for configuration representation
├── output/
│   ├── console.ex             # Runtime console logging functions
│   └── formatter.ex           # Output formatting utilities (simple, detailed, JSON)
└── elixir_ast.ex              # Main public API module
```

### Performance Requirements

| Operation                  | Target           | Measurement                                         |
|----------------------------|------------------|-----------------------------------------------------|
| **AST Parsing (Source)**   | <10ms per module | Time to parse source string and assign node IDs     |
| **Instrumentation Config** | <1ms per call    | Time for each builder API call                      |
| **AST Transformation**     | <50ms per module | Time to apply instrumentation config and transform AST |
| **Memory Usage (Lib)**     | <5MB             | Library's own memory footprint during compilation   |
| **Compilation Impact**     | <20% overhead    | Additional compile time for an instrumented project |

*Note: Per-module targets assume an average module size of 300-500 LOC.*

## 5. API Specification

```elixir
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

  alias ElixirAST.{Builder, Core, Output}

  # ============================================================================
  # Core Types
  # ============================================================================

  @typedoc "Abstract Syntax Tree node"
  @type ast_node() :: term()

  @typedoc "Unique identifier for an AST node after parsing"
  @type node_id() :: binary()

  @typedoc "Instrumentation configuration state"
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
    Builder.instrument_functions(config, target_spec, instrumentation_opts)
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
    Builder.capture_variables(config, variables, opts)
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
    Builder.track_expressions(config, expressions, opts)
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
    Builder.inject_at_line(config, line_number, code, opts)
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
    Builder.inject_before_return(config, code, opts)
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
    Builder.inject_on_error(config, code, opts)
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
    Builder.target_pattern(config, pattern_name)
  end

  @doc """
  Configures the output target for instrumentation logs.
  Currently, only `:console` is supported for the MVP.
  
  ## Examples
      ElixirAST.new() |> ElixirAST.output_to(:console)
  """
  @spec output_to(instrumentation_config(), :console) :: instrumentation_config()
  def output_to(config, target) do
    Builder.output_to(config, target)
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
    Builder.format(config, format_type)
  end

  # ============================================================================
  # Transformation API
  # ============================================================================

  @doc """
  Transforms a given AST node based on the provided instrumentation configuration.
  This is the main function to apply instrumentation.
  
  ## Examples
      {:ok, ast} = ElixirAST.parse(source_code)
      config = ElixirAST.new() |> ElixirAST.instrument_functions(:all)
      {:ok, instrumented_ast} = ElixirAST.transform(config, ast)
  """
  @spec transform(instrumentation_config(), ast_node()) :: transformation_result()
  def transform(config, ast) do
    Core.Transformer.transform(config, ast)
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
    Core.Parser.parse(source_code)
  end

  @doc """
  A convenience function that combines parsing source code and transforming the resulting AST.
  
  ## Examples
      config = ElixirAST.new() |> ElixirAST.instrument_functions(:all)
      source_code = "def my_fun, do: :ok"
      {:ok, instrumented_ast} = ElixirAST.parse_and_transform(config, source_code)
  """
  @spec parse_and_transform(instrumentation_config(), binary()) :: transformation_result()
  def parse_and_transform(config, source_code) do
    with {:ok, ast} <- parse(source_code),
         {:ok, instrumented_ast} <- transform(config, ast) do
      {:ok, instrumented_ast}
    end
  end

  # ============================================================================
  # Utility Functions
  # ============================================================================

  @doc """
  Analyzes an AST to identify instrumentable components and patterns.
  Returns a map containing information like function definitions, detected patterns, etc.
  This can be useful for deciding how to configure instrumentation.
  
  ## Examples
      {:ok, ast} = ElixirAST.parse(source_code)
      analysis_report = ElixirAST.analyze(ast)
      # %{
      #   functions: [%{name: :hello, arity: 1, line: 1, type: :def}],
      #   patterns_detected: [:simple_function],
      #   node_count: 15, # Example node count
      #   complexity_estimate: :low
      # }
  """
  @spec analyze(ast_node()) :: map()
  def analyze(ast) do
    Core.Analyzer.analyze(ast)
  end

  @doc """
  Generates a preview of the instrumentation that would be applied
  based on the configuration, without actually transforming the AST.
  Returns a map detailing the instrumentation points and actions.
  
  ## Examples
      config = ElixirAST.new() |> ElixirAST.instrument_functions(:all)
      {:ok, ast} = ElixirAST.parse(source_code)
      instrumentation_preview = ElixirAST.preview(config, ast)
      # %{
      #   target_functions: [...],
      #   injections: [%{type: :log_entry, target: {MyModule, :my_func, 1}}, ...],
      #   variable_captures: [...]
      # }
  """
  @spec preview(instrumentation_config(), ast_node()) :: map()
  def preview(config, ast) do
    Core.Transformer.preview(config, ast)
  end

  @doc """
  Validates the provided instrumentation configuration.
  Returns `:ok` if the configuration is valid, or `{:error, reasons}` otherwise.
  
  ## Examples
      config = ElixirAST.new() |> ElixirAST.instrument_functions(:invalid_target_spec)
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
  # Convenience Functions
  # ============================================================================

  @doc """
  A quick way to instrument all functions in a source string for entry/exit logging
  and optionally capture specified variables. Output goes to the console.
  
  ## `opts`
  - `capture_vars`: `[atom()] | :all` - Variables to capture. Default `[]`.
  - `log_args`: `boolean()` - Log function arguments. Default `true`.
  - `log_return`: `boolean()` - Log function return value. Default `true`.
  
  ## Examples
      # Instrument all functions with entry/exit logging
      {:ok, ast} = ElixirAST.quick_instrument(source_code)
      
      # Instrument and capture specific variables
      {:ok, ast} = ElixirAST.quick_instrument(source_code, capture_vars: [:result, :user_state])
  """
  @spec quick_instrument(binary(), keyword()) :: transformation_result()
  def quick_instrument(source_code, opts \\ []) do
    log_entry_exit_opts = [
      capture_args: Keyword.get(opts, :log_args, true),
      capture_return: Keyword.get(opts, :log_return, true)
    ]

    config = new(output_format: Keyword.get(opts, :format, :simple))
    |> instrument_functions(:all, log_entry_exit: log_entry_exit_opts)
    |> capture_variables(Keyword.get(opts, :capture_vars, []), at: :before_return)
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
      {:ok, ast} = ElixirAST.instrument_genserver(genserver_source_code)
      
      {:ok, ast} = ElixirAST.instrument_genserver(genserver_source_code, capture_vars: [:state, :msg, :from])
  """
  @spec instrument_genserver(binary(), keyword()) :: transformation_result()
  def instrument_genserver(source_code, opts \\ []) do
    default_genserver_vars = [:state, :new_state, :msg, :from, :reason, :value] # Common GenServer var names
    vars_to_capture = Keyword.get(opts, :capture_vars, default_genserver_vars)

    log_entry_exit_opts = Keyword.get(opts, :log_entry_exit, [capture_args: true, capture_return: true, log_duration: true])

    config = new(output_format: Keyword.get(opts, :format, :detailed))
    |> target_pattern(:genserver_callbacks)
    |> instrument_functions(:all, log_entry_exit: log_entry_exit_opts)
    |> capture_variables(vars_to_capture, at: :before_return) # Capture state just before returning new state
    |> capture_variables(vars_to_capture, at: :entry)         # Capture state at entry
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
      {:ok, ast} = ElixirAST.instrument_phoenix_controller(controller_source_code)
  """
  @spec instrument_phoenix_controller(binary(), keyword()) :: transformation_result()
  def instrument_phoenix_controller(source_code, opts \\ []) do
    vars_to_capture = Keyword.get(opts, :capture_vars, [:conn, :params])
    log_entry_exit_opts = Keyword.get(opts, :log_entry_exit, [capture_args: true, capture_return: true, log_duration: true])

    config = new(output_format: Keyword.get(opts, :format, :detailed))
    |> target_pattern(:phoenix_actions)
    |> instrument_functions(:all, log_entry_exit: log_entry_exit_opts)
    |> capture_variables(vars_to_capture, at: :entry)
    |> output_to(:console)
    
    parse_and_transform(config, source_code)
  end
end

# ============================================================================
# Supporting Modules (API Overview - For Internal Structure, Not Direct User API)
# ============================================================================

defmodule ElixirAST.Builder do
  @moduledoc """
  Internal. Fluent API builder for ElixirAST instrumentation configuration.
  This module holds the state of the configuration being built.
  """
  
  defstruct [
    # Function targeting
    function_target_spec: {:instrument, :all}, # {:instrument | :skip, :all | :public | :private | {:only, list} | {:except, list}}
    pattern_targets: [], # list of pattern atoms like :genserver_callbacks
    
    # Instrumentation actions
    log_function_entry_exit_opts: nil, # log_entry_exit_opts() | nil
    
    variables_to_capture: %{}, # %{capture_point_atom => [vars_to_capture_list_or_all_atom]}
                               # capture_point_atom e.g. :entry, :before_return, {:line, num}
    
    expressions_to_track: [], # list of {quoted_expression, track_expressions_opts()}
    
    custom_injections: %{}, # %{injection_point_atom => [{quoted_code, injection_opts()}]}
                            # injection_point_atom e.g. :at_line_N, :before_return, :on_error
    
    # Output configuration
    output_target: :console,
    output_format: :simple, # :simple | :detailed | :json
    verbose_mode: false
  ]
  
  # Internal functions to update the struct based on ElixirAST API calls...
  def new(_opts), do: %__MODULE__{} # Simplified
  def instrument_functions(config, _target_spec, _instrumentation_opts), do: config # Placeholder
  def capture_variables(config, _variables, _opts), do: config # Placeholder
  def track_expressions(config, _expressions, _opts), do: config # Placeholder
  def inject_at_line(config, _line_number, _code, _opts), do: config # Placeholder
  def inject_before_return(config, _code, _opts), do: config # Placeholder
  def inject_on_error(config, _code, _opts), do: config # Placeholder
  def target_pattern(config, _pattern_name), do: config # Placeholder
  def output_to(config, _target), do: config # Placeholder
  def format(config, _format_type), do: config # Placeholder
  def validate(_config), do: :ok # Placeholder
end

defmodule ElixirAST.Core.Parser do
  @moduledoc "Internal. AST parsing with unique node identification."
  
  @spec parse(binary()) :: {:ok, ElixirAST.ast_node()} | {:error, term()}
  def parse(_source_code) do
    # Implementation: Code.string_to_quoted/1 + assign_node_ids/1
    {:error, :not_implemented_for_prd}
  end
  
  @spec assign_node_ids(ElixirAST.ast_node()) :: ElixirAST.ast_node()
  def assign_node_ids(_ast) do
    # Implementation: Traverse AST, add :elixir_ast_node_id to metadata
    {:error, :not_implemented_for_prd}
  end
end

defmodule ElixirAST.Core.Analyzer do
  @moduledoc "Internal. Code analysis and pattern detection."
  
  @spec analyze(ElixirAST.ast_node()) :: map()
  def analyze(_ast) do
    # Implementation: Traverse AST, identify functions, patterns, complexity.
    # Returns map like %{functions: [...], patterns_detected: [...], ...}
    %{error: :not_implemented_for_prd}
  end
  
  @spec detect_patterns(ElixirAST.ast_node(), [atom()]) :: [atom()]
  def detect_patterns(_ast, _pattern_targets) do
    # Implementation: Match AST against known patterns.
    [:error_not_implemented_for_prd]
  end
end

defmodule ElixirAST.Core.Transformer do
  @moduledoc "Internal. AST transformation and instrumentation injection."
  
  @spec transform(ElixirAST.instrumentation_config(), ElixirAST.ast_node()) :: ElixirAST.transformation_result()
  def transform(_config, _ast) do
    # Implementation: Traverse AST, use Injector to modify based on config.
    {:error, :not_implemented_for_prd}
  end
  
  @spec preview(ElixirAST.instrumentation_config(), ElixirAST.ast_node()) :: map()
  def preview(_config, _ast) do
    # Implementation: Similar to transform but returns description of changes.
    %{error: :not_implemented_for_prd}
  end
end

defmodule ElixirAST.Core.Injector do
  @moduledoc "Internal. Utilities for generating and injecting instrumentation code snippets."
  # Contains functions like:
  # - inject_entry_log(function_head_ast, capture_args_opt) -> new_body_prefix_ast
  # - inject_exit_log(function_body_ast, capture_return_opt) -> new_body_ast_with_try_catch
  # - inject_variable_capture(var_name_atom, line_ast_or_node_id) -> injection_ast
  # - inject_custom_code(target_node_ast, custom_code_ast, position_atom) -> modified_target_node_ast
end

defmodule ElixirAST.Output.Console do
  @moduledoc "Internal. Runtime functions called by instrumented code to log to console."
  
  @spec log_event(map()) :: :ok
  def log_event(_event_data_map) do # Called by injected code
    # Implementation: Format and IO.puts based on config.
    :ok # Placeholder
  end

  # Specific loggers called by generated code (which then call log_event)
  @spec log_function_entry(module(), atom(), [term()], keyword()) :: :ok
  def log_function_entry(_module, _function, _args, _opts), do: :ok

  @spec log_function_exit(module(), atom(), term(), keyword()) :: :ok  
  def log_function_exit(_module, _function, _result, _opts), do: :ok
  
  @spec log_variable_capture(binary(), atom(), term(), keyword()) :: :ok
  def log_variable_capture(_node_id, _var_name, _value, _opts), do: :ok

  @spec log_expression_value(binary(), binary(), term(), keyword()) :: :ok
  def log_expression_value(_node_id, _expression_string, _value, _opts), do: :ok

  @spec log_error(binary(), term(), term(), list(), keyword()) :: :ok
  def log_error(_node_id, _kind, _reason, _stacktrace, _opts), do: :ok
end

defmodule ElixirAST.Patterns do
  @moduledoc "Internal. Defines and matches common Elixir code patterns."
  # Contains functions like:
  # - match_genserver_callbacks(ast_node) -> boolean
  # - match_phoenix_actions(ast_node) -> boolean
end
```

## 6. Implementation Plan

### Week 1: Core Foundation & Parser (Days 1-5)
- **Day 1-2: Project Setup, `ElixirAST` Shell, `Builder` Structs**
    - [x] Mix project generation, dependencies (if any for MVP, likely none beyond Elixir core).
    - [x] Define main `ElixirAST` module with public API function signatures (stubs).
    - [x] Define `ElixirAST.Builder` defstruct and `new/1` function.
    - [x] Basic test framework setup.
- **Day 3-5: `Core.Parser` & Node ID Assignment**
    - [ ] Implement `ElixirAST.Core.Parser.parse/1` (source to AST).
    - [ ] Implement `ElixirAST.Core.Parser.assign_node_ids/1` to traverse AST and add unique `:elixir_ast_node_id` to metadata of relevant nodes.
    - [ ] Unit tests for parser and node ID assignment.

### Week 2: API Implementation & Analyzer (Days 6-10)
- **Day 6-8: `ElixirAST.Builder` API Logic**
    - [ ] Implement all builder functions in `ElixirAST.Builder` to correctly update the configuration struct.
    - [ ] Implement `ElixirAST.Builder.validate/1` for basic config validation.
    - [ ] Unit tests for each builder function and validation.
- **Day 9-10: `Core.Analyzer` Basics & `ElixirAST.Patterns`**
    - [ ] Implement `ElixirAST.Core.Analyzer.analyze/1` to extract basic info (list of functions, etc.).
    - [ ] Implement `ElixirAST.Core.Analyzer.detect_patterns/2` and define initial patterns in `ElixirAST.Patterns` (e.g., `:genserver_callbacks`, `:public_functions`).
    - [ ] Unit tests for analyzer and pattern detection.

### Week 3: Transformer & Injector (Days 11-15)
- **Day 11-13: `Core.Transformer` & `Core.Injector`**
    - [ ] Implement `ElixirAST.Core.Transformer.transform/2` to traverse AST based on `Builder` config.
    - [ ] Implement `ElixirAST.Core.Injector` helpers to generate AST snippets for console logging (e.g., `quote(do: ElixirAST.Output.Console.log_event(...))`).
    - [ ] Focus on `instrument_functions` with `log_entry_exit` first.
    - [ ] Unit tests for basic transformations.
- **Day 14-15: Console Output & Formatting**
    - [ ] Implement `ElixirAST.Output.Console.log_event/1`.
    - [ ] Implement `ElixirAST.Output.Formatter` for `:simple`, `:detailed`, `:json` formats.
    - [ ] Unit tests for console output and formatting.

### Week 4: Advanced Instrumentation & Examples (Days 16-20)
- **Day 16-18: Implement Remaining Instrumentation Features**
    - [ ] Add `capture_variables` logic to `Transformer` and `Injector`.
    - [ ] Add `track_expressions` logic.
    - [ ] Add `inject_at_line`, `inject_before_return`, `inject_on_error` logic.
    - [ ] Unit tests for these advanced features.
- **Day 19-20: Example Scripts & Documentation**
    - [ ] Create example scripts as detailed in Section 7.
    - [ ] Write comprehensive `README.md` and `Hex.pm` docs for the public API.
    - [ ] Basic performance benchmarks for parsing and transformation.

## 7. Example Usage Scenarios

```elixir
# ============================================================================
# ElixirAST Usage Examples
# ============================================================================

# To run these examples:
# 1. Ensure ElixirAST library is compiled and available.
# 2. Execute the `run/0` function of each example module.
#    e.g., Example1.BasicInstrumentation.run()

# Example 1: Basic Function Instrumentation
defmodule Example1.BasicInstrumentation do
  @doc """
  Simple function entry/exit logging for all functions.
  Logs arguments on entry and result on exit.
  """
  
  def run do
    source_code = """
    defmodule Calculator do
      def add(a, b) do
        result = a + b
        # IO.puts "Inside add" # Original code might have this
        result
      end
      
      defp multiply(a, b) do
        a * b
      end

      def process(x) do
        intermediate = multiply(x, 2)
        add(intermediate, 5)
      end
    end
    """
    
    # Configure instrumentation
    config = ElixirAST.new()
    |> ElixirAST.instrument_functions(:all, log_entry_exit: [capture_args: true, capture_return: true, log_duration: true])
    |> ElixirAST.output_to(:console) # Default, explicit for clarity
    |> ElixirAST.format(:simple)     # Default, explicit for clarity
    
    # Transform and compile
    {:ok, instrumented_ast} = ElixirAST.parse_and_transform(config, source_code)
    
    # For demonstration, print the instrumented code (optional)
    # IO.puts "\n--- Instrumented Code (Example 1) ---"
    # IO.puts Macro.to_string(instrumented_ast)
    # IO.puts "-------------------------------------\n"

    [{module, _binary}] = Code.compile_quoted(instrumented_ast, "example1_calculator.ex")
    
    # Test the instrumented code
    IO.puts "\n=== Testing Basic Instrumentation (Example 1) ==="
    IO.puts "Calling #{module}.process(10)..."
    result_process = module.process(10)
    
    IO.puts "\nCalling #{module}.add(5, 3)..."
    result_add = module.add(5, 3)
        
    IO.puts "\nFinal results: process(10) = #{inspect result_process}, add(5,3) = #{inspect result_add}"
    IO.puts "=============================================\n"
  end
end

# Expected Output (Example 1 - simple format):
# === Testing Basic Instrumentation (Example 1) ===
# Calling ElixirAST.Transformed.Calculator.process(10)...
# [ENTRY] ElixirAST.Transformed.Calculator.process/1 ARGS: [10]
# [ENTRY] ElixirAST.Transformed.Calculator.multiply/2 ARGS: [10, 2]
# [EXIT]  ElixirAST.Transformed.Calculator.multiply/2 RETURNED: 20 DURATION: <X> us
# [ENTRY] ElixirAST.Transformed.Calculator.add/2 ARGS: [20, 5]
# [EXIT]  ElixirAST.Transformed.Calculator.add/2 RETURNED: 25 DURATION: <Y> us
# [EXIT]  ElixirAST.Transformed.Calculator.process/1 RETURNED: 25 DURATION: <Z> us
# 
# Calling ElixirAST.Transformed.Calculator.add(5, 3)...
# [ENTRY] ElixirAST.Transformed.Calculator.add/2 ARGS: [5, 3]
# [EXIT]  ElixirAST.Transformed.Calculator.add/2 RETURNED: 8 DURATION: <A> us
#
# Final results: process(10) = 25, add(5,3) = 8
# =============================================

# ============================================================================

# Example 2: Variable Capture
defmodule Example2.VariableCapture do
  @doc """
  Capture and log local variables during function execution.
  Uses detailed format for more context.
  """
  
  def run do
    source_code = """
    defmodule UserService do
      def process_user(user_data) do
        validated_user = validate(user_data) # line 3
        enriched_user = enrich(validated_user) # line 4
        final_result = save(enriched_user) # line 5
        {:ok, final_result} # line 6
      end
      
      defp validate(user), do: Map.put(user, :validated_at, System.monotonic_time())
      defp enrich(user), do: Map.put(user, :enriched_at, System.monotonic_time())
      defp save(user), do: Map.put(user, :id, "user_" <> Integer.to_string(:rand.uniform(1000)))
    end
    """
    
    config = ElixirAST.new()
    |> ElixirAST.instrument_functions({:only, [:process_user]}, log_entry_exit: [capture_args: true, capture_return: true])
    # Capture specific variables before the function returns
    |> ElixirAST.capture_variables([:validated_user, :enriched_user, :final_result], at: :before_return)
    # Capture 'validated_user' after line 3 (where it's assigned)
    |> ElixirAST.capture_variables([:validated_user], at: {:line, 3})
    |> ElixirAST.output_to(:console)
    |> ElixirAST.format(:detailed) # Use detailed format
    
    {:ok, instrumented_ast} = ElixirAST.parse_and_transform(config, source_code)
    [{module, _}] = Code.compile_quoted(instrumented_ast, "example2_userservice.ex")
    
    IO.puts "\n=== Testing Variable Capture (Example 2) ==="
    user_data = %{name: "Alice", email: "alice@example.com"}
    IO.puts "Calling #{module}.process_user(#{inspect user_data})..."
    result = module.process_user(user_data)
    
    IO.puts "\nFinal result: #{inspect(result)}"
    IO.puts "========================================\n"
  end
end

# Expected Output (Example 2 - detailed format, timestamps/PIDs will vary):
# === Testing Variable Capture (Example 2) ===
# Calling ElixirAST.Transformed.UserService.process_user(%{email: "alice@example.com", name: "Alice"})...
# [<timestamp> <pid> ENTRY] ElixirAST.Transformed.UserService.process_user/1 ARGS: [%{email: "alice@example.com", name: "Alice"}]
# [<timestamp> <pid> VAR_CAPTURE AT LINE 3] validated_user = %{email: "alice@example.com", name: "Alice", validated_at: <ts1>}
# [<timestamp> <pid> VAR_CAPTURE BEFORE_RETURN] validated_user = %{email: "alice@example.com", name: "Alice", validated_at: <ts1>}, enriched_user = %{email: "alice@example.com", name: "Alice", validated_at: <ts1>, enriched_at: <ts2>}, final_result = %{email: "alice@example.com", name: "Alice", validated_at: <ts1>, enriched_at: <ts2>, id: "user_<id>"}
# [<timestamp> <pid> EXIT]  ElixirAST.Transformed.UserService.process_user/1 RETURNED: {:ok, %{...id: "user_<id>"...}}
#
# Final result: {:ok, %{email: "alice@example.com", enriched_at: <ts2>, id: "user_<id>", name: "Alice", validated_at: <ts1>}}
# ========================================

# ============================================================================

# Example 3: GenServer Pattern Instrumentation
defmodule Example3.GenServerInstrumentation do
  @doc """
  Automatically instrument GenServer callbacks with state tracking.
  Uses structured JSON format for output.
  """
  
  def run do
    source_code = """
    defmodule CounterServer do
      use GenServer
      
      def start_link(initial_value \\ 0) do
        GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
      end
      
      def increment(pid, amount \\ 1) do
        GenServer.call(pid, {:increment, amount})
      end
      
      def get_value(pid) do
        GenServer.call(pid, :get_value)
      end
      
      # GenServer callbacks
      def init(initial_value) do
        IO.puts "Original init called with #{initial_value}" # For seeing original behavior
        {:ok, %{count: initial_value, history: [:initialized]}}
      end
      
      def handle_call({:increment, amount}, _from, state) do
        new_count = state.count + amount
        new_state = %{state | count: new_count, history: [:incremented | state.history]}
        {:reply, new_count, new_state}
      end
      
      def handle_call(:get_value, _from, state) do
        {:reply, state.count, state}
      end

      def handle_cast(:reset, state) do
        {:noreply, %{state | count: 0, history: [:reset | state.history]}}
      end
    end
    """
    
    config = ElixirAST.new()
    |> ElixirAST.target_pattern(:genserver_callbacks)
    # Instrument all functions matching the pattern (GenServer callbacks)
    |> ElixirAST.instrument_functions(:all, log_entry_exit: [capture_args: true, capture_return: true])
    # Capture 'state' at entry and 'new_state' or 'state' before return for all targeted functions
    |> ElixirAST.capture_variables([:state, :new_state], at: :entry) 
    |> ElixirAST.capture_variables([:state, :new_state], at: :before_return)
    |> ElixirAST.output_to(:console)
    |> ElixirAST.format(:json) # Use JSON format
    
    {:ok, instrumented_ast} = ElixirAST.parse_and_transform(config, source_code)
    [{module, _}] = Code.compile_quoted(instrumented_ast, "example3_counterserver.ex")
    
    IO.puts "\n=== Testing GenServer Instrumentation (Example 3) ==="
    
    # Start the server
    {:ok, pid} = module.start_link(10)
    IO.puts "GenServer started with PID: #{inspect pid}"
    
    # Test operations
    result_inc = module.increment(pid, 5)
    result_get = module.get_value(pid)
    GenServer.cast(pid, :reset) # Cast doesn't return a value from client side
    :timer.sleep(50) # Allow cast to process
    result_get_after_reset = module.get_value(pid)
    
    IO.puts "\nIncrement result: #{inspect result_inc}"
    IO.puts "Get value result: #{inspect result_get}"
    IO.puts "Get value after reset: #{inspect result_get_after_reset}"
    IO.puts "===================================================\n"
    
    # Stop the server
    GenServer.stop(pid)
  end
end

# Expected Output (Example 3 - JSON format, contents will vary):
# Each log line will be a JSON object, e.g.:
# {"timestamp": "...", "pid": "...", "type": "entry", "module": "ElixirAST.Transformed.CounterServer", "function": "init", "arity": 1, "args": [10]}
# {"timestamp": "...", "pid": "...", "type": "variable_capture", "at": "entry", "module": "...", "function": "init", "variables": {"state": {"count":10,"history":[...]}}}
# ... many such lines ...

# ============================================================================

# Example 4: Custom Injection Points & Expression Tracking
defmodule Example4.CustomInjectionsAndTracking do
  @doc """
  Add custom logging, error handling, and track specific expression values.
  """
  
  def run do
    source_code = """
    defmodule PaymentProcessor do
      def process_payment(amount, card_token) do # line 2
        IO.puts "Original process_payment: Validating amount..." # line 3
        if amount <= 0 do # line 4
          Logger.error "Invalid payment amount: #{amount}" # line 5
          raise ArgumentError, "Invalid amount: \#{amount}" # line 6
        end
        
        IO.puts "Original process_payment: Charging card..." # line 9
        charge_result = charge_card(card_token, amount) # line 10, expression to track

        IO.puts "Original process_payment: Processing charge result..." # line 12
        case charge_result do # line 13
          {:ok, charge_id} -> # line 14
            # line 15: Success path
            transaction_status = record_transaction(charge_id, amount) # line 16, expression to track
            final_outcome = {:ok, charge_id, transaction_status} # line 17
            final_outcome # line 18
          
          {:error, reason} -> # line 20
            # line 21: Error path  
            error_details = log_failed_payment(reason, amount) # line 22
            final_outcome = {:error, reason, error_details} # line 23
            final_outcome # line 24
        end
      end
      
      defp charge_card(_token, amount) do
        # Simulate API call
        if amount > 1000, do: {:error, :insufficient_funds}, else: {:ok, "ch_#{:rand.uniform(1_000_000)}"}
      end
      defp record_transaction(charge_id, amount), do: %{status: :completed, charge_id: charge_id, amount: amount}
      defp log_failed_payment(reason, amount), do: %{reason: reason, amount: amount, logged_at: DateTime.utc_now()}
    end
    """
    
    config = ElixirAST.new()
    |> ElixirAST.instrument_functions({:only, [:process_payment]}, log_entry_exit: [capture_args: true, capture_return: true])
    # Custom injection after line 10
    |> ElixirAST.inject_at_line(10, 
        quote(do: ElixirAST.Output.Console.log_event(%{type: :custom_log, message: "Card charged, result: #{inspect charge_result}", location: "after_charge_card"})),
        context_vars: [:charge_result] 
       )
    # Track specific expressions
    |> ElixirAST.track_expressions([
        quote(do: charge_card(card_token, amount)),
        quote(do: record_transaction(charge_id, amount))
       ])
    # Custom injection on error
    |> ElixirAST.inject_on_error(
        quote(do: ElixirAST.Output.Console.log_event(%{type: :custom_error_log, message: "Payment processing failed", error_kind: error, error_reason: reason, input_amount: amount})),
        context_vars: [:amount] # `error`, `reason`, `stacktrace` are implicitly available
       )
    |> ElixirAST.output_to(:console)
    |> ElixirAST.format(:detailed)
    
    {:ok, instrumented_ast} = ElixirAST.parse_and_transform(config, source_code)
    [{module, _}] = Code.compile_quoted(instrumented_ast, "example4_paymentprocessor.ex")
    
    IO.puts "\n=== Testing Custom Injections & Tracking (Example 4) ==="
    IO.puts "Processing successful payment (amount: 100)..."
    result_ok = module.process_payment(100, "tok_valid")
    IO.inspect result_ok, label: "Successful payment result"
    
    IO.puts "\nProcessing payment that fails card charge (amount: 1500)..."
    result_fail_charge = module.process_payment(1500, "tok_funds_low")
    IO.inspect result_fail_charge, label: "Failed card charge result"
    
    IO.puts "\nProcessing payment with invalid amount (amount: -50)..."
    try do
      module.process_payment(-50, "tok_irrelevant")
    rescue
      e -> IO.inspect e, label: "Invalid amount exception"
    end
    IO.puts "======================================================\n"
  end
end

# Expected Output (Example 4 - detailed format, excerpts):
# ...
# [<ts> <pid> ENTRY] ElixirAST.Transformed.PaymentProcessor.process_payment/2 ARGS: [100, "tok_valid"]
# Original process_payment: Validating amount...
# Original process_payment: Charging card...
# [<ts> <pid> EXPRESSION_TRACK] charge_card(card_token, amount) VALUE: {:ok, "ch_<id>"}
# [<ts> <pid> CUSTOM_LOG] message: "Card charged, result: {:ok, \"ch_<id>\"}", location: "after_charge_card"
# Original process_payment: Processing charge result...
# [<ts> <pid> EXPRESSION_TRACK] record_transaction(charge_id, amount) VALUE: %{status: :completed, charge_id: "ch_<id>", amount: 100}
# [<ts> <pid> EXIT] ElixirAST.Transformed.PaymentProcessor.process_payment/2 RETURNED: {:ok, "ch_<id>", %{...}}
# ...
# [<ts> <pid> ENTRY] ElixirAST.Transformed.PaymentProcessor.process_payment/2 ARGS: [-50, "tok_irrelevant"]
# Original process_payment: Validating amount...
# [<ts> <pid> CUSTOM_ERROR_LOG] message: "Payment processing failed", error_kind: ArgumentError, error_reason: %ArgumentError{message: "Invalid amount: -50"}, input_amount: -50
# [<ts> <pid> EXIT] ElixirAST.Transformed.PaymentProcessor.process_payment/2 RAISED: %ArgumentError{message: "Invalid amount: -50"}

```

## 8. Conclusion

ElixirAST MVP aims to provide a robust, developer-friendly foundation for compile-time AST instrumentation in Elixir. Its clean API, focus on core transformation capabilities, and console-based output make it an ideal standalone tool for code understanding and a powerful building block for more advanced observability and debugging systems.

By delivering these core features, ElixirAST will empower developers to gain unprecedented insight into their Elixir code's behavior at compile time, fostering better code quality, easier debugging, and a deeper understanding of Elixir's metaprogramming strengths.