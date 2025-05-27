defmodule ElixirAST.Output.ConsoleTest do
  use ExUnit.Case, async: true # Assuming capture_io is fine with async for these tests

  alias ElixirAST.Output.Console
  alias ElixirAST.Output.Formatter

  # Helper to decode JSON, returning a map indicating error if Jason is not available
  defp decode_json_output(json_string) do
    try do
      Jason.decode!(json_string)
    rescue
      UndefinedFunctionError -> %{"error" => "Jason not available for test decoding"}
    end
  end

  # --- Tests for Core log_event/2 ---
  test "log_event/2 prints formatted simple string to console" do
    event_data = %{type: :custom_log, message: "Hello Simple", module: M, function: :f, arity: 0}
    expected_output = Formatter.format_simple(event_data) <> "\n"
    assert ExUnit.CaptureIO.capture_io(fn -> Console.log_event(event_data, :simple) end) == expected_output
  end

  test "log_event/2 prints formatted detailed string to console" do
    # Detailed format includes timestamp and PID which are dynamic.
    # We'll check for the static parts.
    event_data = %{type: :custom_log, message: "Hello Detailed", module: M, function: :f, arity: 0, timestamp: {1,2,3}, pid: self()}
    # The Formatter.format_detailed will produce the full string with dynamic parts.
    # We capture what Console.log_event produces.
    output = ExUnit.CaptureIO.capture_io(fn -> Console.log_event(event_data, :detailed) end)
    
    assert String.contains?(output, Formatter.format_simple(event_data)) # Contains the simple part
    assert String.contains?(output, inspect(event_data.timestamp))
    assert String.contains?(output, inspect(event_data.pid))
    assert String.ends_with?(output, "\n")
  end

  test "log_event/2 prints formatted JSON string to console" do
    event_data = %{type: :custom_log, message: "Hello JSON", module: M, function: :f, arity: 0, timestamp: {1,2,3}, pid: self()}
    expected_json_string = Formatter.format_json(event_data)
    
    output = ExUnit.CaptureIO.capture_io(fn -> Console.log_event(event_data, :json) end)
    assert String.trim(output) == String.trim(expected_json_string) # Compare trimmed strings

    # Additionally, decode and check key fields if Jason is available
    decoded_output = decode_json_output(output)
    decoded_expected = decode_json_output(expected_json_string)

    if Map.get(decoded_output, "error") != "Jason not available for test decoding" do
      assert decoded_output["type"] == "custom_log"
      assert decoded_output["message"] == "Hello JSON"
      assert Map.get(decoded_output, "pid") == inspect(self()) # Formatter serializes PID
    else
      # If Jason is not available, the fallback string from Formatter is tested in formatter_test.exs
      # Here, we just ensure the output matches what Formatter produced.
      :ok
    end
  end

  # --- Tests for Specific Logger Helper Functions ---
  # These tests check if the helpers correctly construct event_data and pass it to log_event.

  test "log_function_entry/5 logs entry event correctly" do
    m = MyApp.TestModule
    f = :test_func
    a = 2
    args = [123, "abc"]
    runtime_opts = [output_format: :simple, node_id: "node123"]

    output = ExUnit.CaptureIO.capture_io(fn ->
      Console.log_function_entry(m, f, a, args, runtime_opts)
    end)
    
    # Expected event_data structure (excluding dynamic timestamp/pid for simple check)
    # For a more robust check, we'd ideally intercept what's passed to Formatter.format_simple
    # or reconstruct the exact string.
    assert output =~ "[ENTRY]"
    assert output =~ "#{inspect(m)}.#{inspect(f)}/#{a}"
    assert output =~ "ARGS: #{inspect(args)}"
    assert output =~ "(Node: node123)"
    assert String.ends_with?(output, "\n")
  end

  test "log_function_exit/6 logs exit event with duration" do
    m = MyApp.AnotherModule
    f = :another_func
    a = 0
    return_val = {:ok, :done}
    duration = 5000
    runtime_opts = [output_format: :simple, node_id: "nodeExit"]

    output = ExUnit.CaptureIO.capture_io(fn ->
      Console.log_function_exit(m, f, a, return_val, duration, runtime_opts)
    end)

    assert output =~ "[EXIT]"
    assert output =~ "#{inspect(m)}.#{inspect(f)}/#{a}"
    assert output =~ "RETURNED: #{inspect(return_val)}"
    assert output =~ "DURATION: #{duration} us"
    assert output =~ "(Node: nodeExit)"
  end

  test "log_variable_capture/6 logs variable capture event" do
    m = MyApp.VarModule
    f = :process_vars
    a = 1
    capture_point = {:line, 42}
    vars_map = %{user_id: 101, data: %{content: "stuff"}}
    runtime_opts = [output_format: :simple, node_id: "nodeVarCap"]

    output = ExUnit.CaptureIO.capture_io(fn ->
      Console.log_variable_capture(m, f, a, capture_point, vars_map, runtime_opts)
    end)

    assert output =~ "[VAR CAPTURE]"
    assert output =~ "#{inspect(m)}.#{inspect(f)}/#{a}"
    assert output =~ "AT LINE 42:" # Formatted capture point
    assert output =~ inspect(vars_map)
    assert output =~ "(Node: nodeVarCap)"
  end

  test "log_expression_value/6 logs expression value event" do
    m = MyApp.ExprModule
    f = :eval_expr
    a = 0
    expr_str = "calculate_total(order)"
    value = 199.99
    runtime_opts = [output_format: :simple, node_id: "nodeExprVal"]

    output = ExUnit.CaptureIO.capture_io(fn ->
      Console.log_expression_value(m, f, a, expr_str, value, runtime_opts)
    end)

    assert output =~ "[EXPR VALUE]"
    assert output =~ "#{inspect(m)}.#{inspect(f)}/#{a}"
    assert output =~ "'#{expr_str}' VALUE: #{inspect(value)}"
    assert output =~ "(Node: nodeExprVal)"
  end

  test "log_error/7 logs error event with stacktrace" do
    m = MyApp.ErrorModule
    f = :risky_operation
    a = 1
    kind = :error
    reason = %RuntimeError{message: "boom"}
    stack = [{Mod, :fun, 2, [file: 'mod.ex', line: 10]}] # Sample stacktrace term
    runtime_opts = [output_format: :simple, node_id: "nodeErr"]

    output = ExUnit.CaptureIO.capture_io(fn ->
      Console.log_error(m, f, a, kind, reason, stack, runtime_opts)
    end)

    assert output =~ "[ERROR LOG]"
    assert output =~ "#{inspect(m)}.#{inspect(f)}/#{a}"
    assert output =~ "ERROR: #{inspect(kind)}"
    assert output =~ "REASON: #{inspect(reason)}"
    # The formatted stacktrace is complex; check for a part of it.
    assert output =~ "Mod.fun/2" 
    assert output =~ "(Node: nodeErr)"
  end

  test "log_custom_event/2 logs custom event data" do
    custom_data = %{
      type: :my_custom_type, # Overrides default :custom_log
      module: MyCustom.Mod,  # Provided
      function: :my_func,    # Provided
      arity: 1,              # Provided
      custom_field1: "value1",
      custom_field2: 12345
    }
    runtime_opts = [output_format: :simple, node_id: "nodeCustom"]

    output = ExUnit.CaptureIO.capture_io(fn ->
      Console.log_custom_event(custom_data, runtime_opts)
    end)

    # Check if type is overridden and custom fields are present
    assert output =~ "[MY CUSTOM TYPE]"
    assert output =~ "MyCustom.Mod.my_func/1"
    assert output =~ "Details: %{custom_field1: \"value1\", custom_field2: 12345}" # Based on Formatter's generic fallback
    assert output =~ "(Node: nodeCustom)"
  end
  
  test "log_custom_event/2 adds timestamp and pid if not provided" do
    custom_data = %{message: "A simple custom log"} # No type, timestamp, pid
    runtime_opts = [output_format: :detailed] # Use detailed to check for ts/pid

    output = ExUnit.CaptureIO.capture_io(fn ->
      Console.log_custom_event(custom_data, runtime_opts)
    end)

    assert output =~ "[CUSTOM LOG]" # Default type
    assert output =~ "UnknownModule.unknown_function/?" # Default location if not in map
    assert output =~ "message: \"A simple custom log\""
    assert output =~ ~r/<\d+\.\d+\.\d+>/ # PID should be added
    assert output =~ ~r/{\d+, \d+, \d+}/ # Timestamp should be added (inspect format)
  end

  # The conceptual test for color-coding is hard to verify automatically without knowing
  # the exact ANSI codes. This is better as a manual/visual check if implemented.
  # test "log_event/1 uses color-coding for console output (conceptual test)" do
  # end
  end
end
