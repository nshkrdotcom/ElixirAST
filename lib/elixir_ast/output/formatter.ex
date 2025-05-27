defmodule ElixirAST.Output.Formatter do
  @moduledoc """
  Formats instrumentation event data into various string representations.
  """

  @type event_map() :: map() # Represents the conceptual event map

  # --- Simple Formatter ---

  @doc """
  Formats an event map into a concise, human-readable string.
  """
  @spec format_simple(event_map()) :: String.t()
  def format_simple(event_map) do
    base = "[#{format_type(Map.get(event_map, :type, :unknown))}] #{format_location(event_map)}"

    details =
      case event_map.type do
        :entry -> "ARGS: #{inspect(Map.get(event_map, :args))}"
        :exit -> "RETURNED: #{inspect(Map.get(event_map, :return_value))}" <> format_duration(Map.get(event_map, :duration))
        :var_capture -> "#{format_capture_point(Map.get(event_map, :at))} #{inspect(Map.get(event_map, :variables))}"
        :expr_value -> "'#{Map.get(event_map, :expression_string, "???")}' VALUE: #{inspect(Map.get(event_map, :value))}"
        :custom_log ->
          message = Map.get(event_map, :message, "")
          location = Map.get(event_map, :location)
          message <> (if location, do: " AT: #{location}", else: "")
        :error_log -> "ERROR: #{inspect(Map.get(event_map, :kind))} REASON: #{inspect(Map.get(event_map, :reason))}"
        _ ->
          # Generic fallback for unknown or partially formed event types
          generic_details = Map.drop(event_map, [:type, :module, :function, :arity, :timestamp, :pid, :node_id, :args, :return_value, :duration, :variables, :at, :expression_string, :value, :message, :location, :kind, :reason])
          if map_size(generic_details) > 0 do
            "Details: #{inspect(generic_details)}"
          else
            "" # No extra details if all known fields were dropped or absent
          end
      end

    # Ensure base and details are properly concatenated, handling cases where details might be empty.
    if String.trim(details) == "" do
      String.trim(base)
    else
      String.trim("#{base} #{details}")
    end
  end

  defp format_type(type_atom) when is_atom(type_atom) do
    type_atom |> Atom.to_string() |> String.upcase() |> String.replace("_", " ")
  end
  defp format_type(_), do: "UNKNOWN_EVENT"


  defp format_location(event_map) do
    module_name = Map.get(event_map, :module, "UnknownModule")
    func_name = Map.get(event_map, :function, "unknown_function")
    arity = Map.get(event_map, :arity, "?")
    node_id_str = if node_id = Map.get(event_map, :node_id), do: " (Node: #{node_id})", else: ""

    "#{module_name}.#{func_name}/#{arity}" <> node_id_str
  end

  defp format_duration(nil), do: ""
  defp format_duration(duration_us) when is_integer(duration_us), do: " DURATION: #{duration_us} us"
  defp format_duration(_), do: "" # Ignore non-integer durations

  defp format_capture_point(:entry), do: "AT ENTRY:"
  defp format_capture_point(:before_return), do: "BEFORE RETURN:"
  defp format_capture_point(:on_error), do: "ON ERROR:"
  defp format_capture_point({:line, l}) when is_integer(l), do: "AT LINE #{l}:"
  defp format_capture_point(other), do: "AT #{inspect(other)}:" # Fallback for unknown capture points

  # --- Detailed Formatter ---

  @doc """
  Formats an event map into a detailed, human-readable string including timestamp and PID.
  """
  @spec format_detailed(event_map()) :: String.t()
  def format_detailed(event_map) do
    timestamp_str = if ts = Map.get(event_map, :timestamp), do: "#{format_timestamp(ts)} ", else: ""
    pid_str = if pid = Map.get(event_map, :pid), do: "<#{inspect(pid)}> ", else: ""

    "#{timestamp_str}#{pid_str}" <> format_simple(event_map) # Reuse simple formatting for the rest
  end

  # Placeholder for timestamp formatting. Using inspect as Calendar might not be available.
  defp format_timestamp(timestamp) when is_tuple(timestamp) do
    # This is a simple inspect. For "2024-05-27T10:00:00.123Z", a proper datetime library is needed.
    inspect(timestamp)
  end
  defp format_timestamp(other), do: inspect(other) # Fallback for other timestamp formats

  # --- JSON Formatter ---

  @doc """
  Formats an event map into a JSON string.
  Attempts to use Jason, falls back to an error string if Jason is not available.
  """
  @spec format_json(event_map()) :: String.t()
  def format_json(event_map) do
    # Ensure all values are JSON encodable (e.g., PIDs might need to be strings)
    serializable_map =
      event_map
      |> Map.update(:pid, nil, fn
        nil -> nil # Keep nil as nil
        pid -> inspect(pid) # Convert PID to string
      end)
      |> Map.update(:timestamp, nil, fn # Ensure timestamp is encodable if it's a complex tuple
        nil -> nil
        ts_tuple when is_tuple(ts_tuple) -> inspect(ts_tuple) # Example: make it a string
        other -> other
      end)
      # Atoms are typically encoded as strings by Jason, which is fine.

    try do
      Jason.encode!(serializable_map)
    rescue
      UndefinedFunctionError ->
        # Fallback if Jason is not available at runtime
        # Note: The inspect call here is a simplified representation for the fallback.
        # A more robust manual JSON construction is complex and generally not recommended.
        data_preview =
          serializable_map
          |> Enum.map(fn {k, v} -> "\"#{k}\": #{limited_inspect(v)}" end)
          |> Enum.join(", ")

        "{\"error\": \"Jason library not configured for encoding\", \"data_preview\": {#{data_preview}}}"
    end
  end

  # Helper for limited inspect in JSON fallback to avoid overly complex strings
  defp limited_inspect(value) when is_binary(value), do: "\"#{value}\"" # Quote strings
  defp limited_inspect(value) when is_atom(value), do: "\"#{value}\""   # Quote atoms
  defp limited_inspect(value) when is_list(value) do
    # Simple list representation, not full JSON array for brevity in fallback
    "[#{Enum.map(value, &limited_inspect/1) |> Enum.join(", ")}]"
  end
  defp limited_inspect(value) when is_map(value) do
    # Simple map representation, not full JSON object for brevity
    "{#{Enum.map(value, fn {k,v} -> "#{limited_inspect(k)}: #{limited_inspect(v)}" end) |> Enum.join(", ")}}"
  end
  defp limited_inspect(value), do: inspect(value) # Numbers, booleans, etc.
end
