defmodule ElixirAST.Output.Console do
  @moduledoc """
  Runtime functions called by instrumented code to log to console.
  """

  alias ElixirAST.Output.Formatter

  @type event_data() :: map()
  @type output_format_option() :: :simple | :detailed | :json
  @type runtime_opts() :: keyword()

  # --- Core Logging Function ---

  @doc """
  Logs formatted event data to the console.
  This function is typically called by specific logger helpers.
  """
  @spec log_event(event_data :: event_data(), output_format :: output_format_option()) :: :ok
  def log_event(event_data, output_format \\ :simple) do
    # Ensure output_format defaults if it's somehow nil, though runtime_opts should provide it.
    effective_format = output_format || :simple

    formatted_string =
      case effective_format do
        :simple -> Formatter.format_simple(event_data)
        :detailed -> Formatter.format_detailed(event_data)
        :json -> Formatter.format_json(event_data)
        _ -> Formatter.format_simple(event_data) # Fallback for unknown format
      end

    IO.puts(formatted_string)
    :ok
  end

  # --- Specific Logger Helper Functions ---

  @doc """
  Logs a function entry event.
  """
  @spec log_function_entry(module :: module(), function_name :: atom(), arity :: non_neg_integer(), args :: list(), runtime_opts :: runtime_opts()) :: :ok
  def log_function_entry(module, function_name, arity, args, runtime_opts \\ []) do
    event_data = %{
      type: :entry,
      module: module,
      function: function_name,
      arity: arity,
      args: args,
      timestamp: current_timestamp(),
      pid: self(),
      node_id: Keyword.get(runtime_opts, :node_id)
    }
    log_event(event_data, Keyword.get(runtime_opts, :output_format, :simple))
  end

  @doc """
  Logs a function exit event.
  """
  @spec log_function_exit(module :: module(), function_name :: atom(), arity :: non_neg_integer(), return_value :: term(), duration_us :: integer(), runtime_opts :: runtime_opts()) :: :ok
  def log_function_exit(module, function_name, arity, return_value, duration_us, runtime_opts \\ []) do
    event_data = %{
      type: :exit,
      module: module,
      function: function_name,
      arity: arity,
      return_value: return_value,
      duration: duration_us,
      timestamp: current_timestamp(),
      pid: self(),
      node_id: Keyword.get(runtime_opts, :node_id)
    }
    log_event(event_data, Keyword.get(runtime_opts, :output_format, :simple))
  end

  @doc """
  Logs a variable capture event.
  """
  @spec log_variable_capture(module :: module(), function_name :: atom(), arity :: non_neg_integer(), capture_point :: atom() | tuple(), variables_map :: map(), runtime_opts :: runtime_opts()) :: :ok
  def log_variable_capture(module, function_name, arity, capture_point, variables_map, runtime_opts \\ []) do
    event_data = %{
      type: :var_capture,
      module: module,
      function: function_name,
      arity: arity,
      at: capture_point,
      variables: variables_map,
      timestamp: current_timestamp(),
      pid: self(),
      node_id: Keyword.get(runtime_opts, :node_id)
    }
    log_event(event_data, Keyword.get(runtime_opts, :output_format, :simple))
  end

  @doc """
  Logs an expression value event.
  """
  @spec log_expression_value(module :: module(), function_name :: atom(), arity :: non_neg_integer(), expression_string :: String.t(), value :: term(), runtime_opts :: runtime_opts()) :: :ok
  def log_expression_value(module, function_name, arity, expression_string, value, runtime_opts \\ []) do
    event_data = %{
      type: :expr_value,
      module: module,
      function: function_name,
      arity: arity,
      expression_string: expression_string,
      value: value,
      timestamp: current_timestamp(),
      pid: self(),
      node_id: Keyword.get(runtime_opts, :node_id)
    }
    log_event(event_data, Keyword.get(runtime_opts, :output_format, :simple))
  end

  @doc """
  Logs an error event.
  """
  @spec log_error(module :: module(), function_name :: atom(), arity :: non_neg_integer(), kind :: atom(), reason :: term(), stacktrace_term :: list(), runtime_opts :: runtime_opts()) :: :ok
  def log_error(module, function_name, arity, kind, reason, stacktrace_term, runtime_opts \\ []) do
    event_data = %{
      type: :error_log,
      module: module,
      function: function_name,
      arity: arity,
      kind: kind,
      reason: reason,
      stacktrace: Exception.format_stacktrace(stacktrace_term),
      timestamp: current_timestamp(),
      pid: self(),
      node_id: Keyword.get(runtime_opts, :node_id)
    }
    log_event(event_data, Keyword.get(runtime_opts, :output_format, :simple))
  end

  @doc """
  Logs a custom event.
  The provided map should contain at least a :type field, or it defaults to :custom_log.
  Common fields like timestamp and pid are added if not already present.
  """
  @spec log_custom_event(event_data_map :: map(), runtime_opts :: runtime_opts()) :: :ok
  def log_custom_event(event_data_map, runtime_opts \\ []) do
    base_event = %{
      type: Map.get(event_data_map, :type, :custom_log), # Default type if not provided
      timestamp: Map.get(event_data_map, :timestamp, current_timestamp()),
      pid: Map.get(event_data_map, :pid, self()),
      node_id: Map.get(event_data_map, :node_id, Keyword.get(runtime_opts, :node_id))
    }

    # Merge ensures provided fields in event_data_map override defaults from base_event,
    # except for :type, :timestamp, :pid, :node_id which are explicitly handled above.
    # However, a more standard merge prefers the second map's values:
    final_event_data = Map.merge(base_event, event_data_map)
    # Ensure that if type was in event_data_map, it is preserved:
    # (Actually, Map.get for :type in base_event already does this)

    log_event(final_event_data, Keyword.get(runtime_opts, :output_format, :simple))
  end

  # --- Private Helper Functions ---

  @doc false
  defp current_timestamp(), do: :os.system_time(:microsecond)
end
