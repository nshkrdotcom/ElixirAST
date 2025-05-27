defmodule ElixirAST.Builder do
  @moduledoc """
  Internal. Fluent API builder for ElixirAST instrumentation configuration.
  This module holds the state of the configuration being built and provides
  functions to update this state.
  """

  # Ensure the types are available if this module is compiled independently
  # or if they are used explicitly in function specs within this module.
  # However, the main ElixirAST module already defines these.
  # If there's a circular dependency risk or for clarity, one might redefine
  # or alias them carefully. For now, assume they are accessible via ElixirAST module.
  # For instance, `ElixirAST.log_entry_exit_opts()`
  # No, the ElixirAST.instrumentation_config() is %ElixirAST.Builder{}
  # So the type is defined here.

  @type t() :: %__MODULE__{}
  @type log_entry_exit_opts() :: ElixirAST.log_entry_exit_opts()
  @type capture_variables_opts() :: ElixirAST.capture_variables_opts()
  @type track_expressions_opts() :: ElixirAST.track_expressions_opts()
  @type injection_opts() :: ElixirAST.injection_opts()
  @type ast_node() :: ElixirAST.ast_node()


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

  @doc """
  Creates a new, empty instrumentation configuration.
  Accepts initial options for output configuration.
  """
  @spec new(keyword()) :: t()
  def new(opts \ []) do
    %__MODULE__{
      output_target: Keyword.get(opts, :output_target, :console),
      output_format: Keyword.get(opts, :output_format, :simple),
      verbose_mode: Keyword.get(opts, :verbose_mode, false)
      # Initialize other fields to their defaults as per defstruct
    }
  end

  @doc """
  Configures which functions to target for instrumentation.
  (Stub implementation)
  """
  @spec instrument_functions(t(), atom() | tuple(), keyword()) :: t()
  def instrument_functions(config, _target_spec, _instrumentation_opts \ []) do
    # Placeholder: In a real implementation, this would update config.function_target_spec
    # and merge options into config.log_function_entry_exit_opts, etc.
    config
  end

  @doc """
  Configures local variable capture for targeted functions.
  (Stub implementation)
  """
  @spec capture_variables(t(), [atom()] | :all, capture_variables_opts()) :: t()
  def capture_variables(config, _variables, _opts \ []) do
    # Placeholder: Update config.variables_to_capture
    config
  end

  @doc """
  Configures tracking for specific expressions.
  (Stub implementation)
  """
  @spec track_expressions(t(), [ast_node()], track_expressions_opts()) :: t()
  def track_expressions(config, _expressions, _opts \ []) do
    # Placeholder: Update config.expressions_to_track
    config
  end

  @doc """
  Injects custom quoted Elixir code at a specific line number.
  (Stub implementation)
  """
  @spec inject_at_line(t(), pos_integer(), ast_node(), injection_opts()) :: t()
  def inject_at_line(config, _line_number, _code, _opts \ []) do
    # Placeholder: Update config.custom_injections
    config
  end

  @doc """
  Injects custom quoted Elixir code immediately before function return statements.
  (Stub implementation)
  """
  @spec inject_before_return(t(), ast_node(), injection_opts()) :: t()
  def inject_before_return(config, _code, _opts \ []) do
    # Placeholder: Update config.custom_injections
    config
  end

  @doc """
  Injects custom quoted Elixir code to be executed when an error is raised.
  (Stub implementation)
  """
  @spec inject_on_error(t(), ast_node(), injection_opts()) :: t()
  def inject_on_error(config, _code, _opts \ []) do
    # Placeholder: Update config.custom_injections
    config
  end

  @doc """
  Configures instrumentation to target functions matching a predefined pattern.
  (Stub implementation)
  """
  @spec target_pattern(t(), atom()) :: t()
  def target_pattern(config, _pattern_name) do
    # Placeholder: Update config.pattern_targets
    config
  end

  @doc """
  Configures the output target for instrumentation logs.
  (Stub implementation)
  """
  @spec output_to(t(), :console) :: t()
  def output_to(config, target) do
    %__MODULE__{config | output_target: target}
  end

  @doc """
  Configures the output format for console logs.
  (Stub implementation)
  """
  @spec format(t(), :simple | :detailed | :json) :: t()
  def format(config, format_type) do
    %__MODULE__{config | output_format: format_type}
  end

  @doc """
  Validates the provided instrumentation configuration.
  (Stub implementation)
  """
  @spec validate(t()) :: :ok | {:error, [term()]}
  def validate(_config) do
    # Placeholder: Real validation logic would go here.
    :ok
  end
end
