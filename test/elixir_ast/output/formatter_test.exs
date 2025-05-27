defmodule ElixirAST.Output.FormatterTest do
  use ExUnit.Case, async: true

  alias ElixirAST.Output.Formatter

  @entry_event %{type: :entry, module: MyApp.MyModule, function: :handle_call, arity: 3, args: [1, "two", %{key: :val}], node_id: "ast_id_def_1"}
  @exit_event %{type: :exit, module: MyApp.MyModule, function: :handle_call, arity: 3, return_value: {:ok, "done"}, duration: 1234, node_id: "ast_id_def_1"}
  @var_capture_event %{type: :var_capture, module: MyApp.MyModule, function: :process, arity: 1, at: :entry, variables: %{user: %{id: 1, name: "Test"}}, node_id: "ast_id_def_2"}
  @expr_value_event %{type: :expr_value, module: MyApp.MyModule, function: :calculate, arity: 0, expression_string: "1 + 1", value: 2, node_id: "ast_id_expr_1"}
  @custom_log_event %{type: :custom_log, module: MyApp.MyModule, function: :debug_point, arity: 0, message: "Custom debug message", location: "checkpoint_alpha", node_id: "ast_id_custom_1"}
  @error_log_event %{type: :error_log, module: MyApp.MyModule, function: :risky_op, arity: 1, kind: :error, reason: "Something went wrong", node_id: "ast_id_err_1"}
  
  @ts {1678, 864000, 123000} # Example Erlang timestamp tuple
  @pid_val self() # Example PID

  @detailed_entry_event Map.merge(@entry_event, %{timestamp: @ts, pid: @pid_val})
  @detailed_exit_event Map.merge(@exit_event, %{timestamp: @ts, pid: @pid_val})


  # --- Tests for format_simple/1 ---
  test "format_simple/1 for :entry event" do
    expected = "[ENTRY] MyApp.MyModule.handle_call/3 (Node: ast_id_def_1) ARGS: [1, \"two\", %{key: :val}]"
    assert Formatter.format_simple(@entry_event) == expected
  end

  test "format_simple/1 for :exit event" do
    expected = "[EXIT] MyApp.MyModule.handle_call/3 (Node: ast_id_def_1) RETURNED: {:ok, \"done\"} DURATION: 1234 us"
    assert Formatter.format_simple(@exit_event) == expected
  end
  
  test "format_simple/1 for :var_capture event" do
    expected = "[VAR CAPTURE] MyApp.MyModule.process/1 (Node: ast_id_def_2) AT ENTRY: %{user: %{id: 1, name: \"Test\"}}"
    assert Formatter.format_simple(@var_capture_event) == expected
  end

  test "format_simple/1 for :expr_value event" do
    expected = "[EXPR VALUE] MyApp.MyModule.calculate/0 (Node: ast_id_expr_1) '1 + 1' VALUE: 2"
    assert Formatter.format_simple(@expr_value_event) == expected
  end
  
  test "format_simple/1 for :custom_log event" do
    expected = "[CUSTOM LOG] MyApp.MyModule.debug_point/0 (Node: ast_id_custom_1) Custom debug message AT: checkpoint_alpha"
    assert Formatter.format_simple(@custom_log_event) == expected
  end

  test "format_simple/1 for :error_log event" do
    expected = "[ERROR LOG] MyApp.MyModule.risky_op/1 (Node: ast_id_err_1) ERROR: :error REASON: \"Something went wrong\""
    assert Formatter.format_simple(@error_log_event) == expected
  end
  
  test "format_simple/1 handles missing optional fields gracefully" do
    minimal_entry = %{type: :entry, module: M, function: :f, arity: 0}
    assert Formatter.format_simple(minimal_entry) == "[ENTRY] M.f/0 ARGS: nil"

    minimal_exit = %{type: :exit, module: M, function: :f, arity: 0, return_value: :ok} # no duration, no node_id
    assert Formatter.format_simple(minimal_exit) == "[EXIT] M.f/0 RETURNED: :ok"
  end

  test "format_simple/1 handles unknown event type" do
    unknown_event = %{type: :weird_event, module: M, function: :f, arity: 0, data: "stuff"}
    assert Formatter.format_simple(unknown_event) == "[WEIRD EVENT] M.f/0 Details: %{data: \"stuff\"}"
  end

  # --- Tests for format_detailed/1 ---
  test "format_detailed/1 for :entry event with timestamp and pid" do
    output = Formatter.format_detailed(@detailed_entry_event)
    simple_part = Formatter.format_simple(@detailed_entry_event)
    
    assert String.starts_with?(output, "#{inspect(@ts)} #{inspect(@pid_val)}")
    assert String.ends_with?(output, simple_part)
  end

  test "format_detailed/1 for :exit event without timestamp or pid" do
    # Should just be the simple format if ts/pid are missing
    output = Formatter.format_detailed(@exit_event)
    simple_part = Formatter.format_simple(@exit_event)
    assert output == simple_part
  end
  
  test "format_detailed/1 for :var_capture event with timestamp and pid" do
    detailed_var_event = Map.merge(@var_capture_event, %{timestamp: @ts, pid: @pid_val})
    output = Formatter.format_detailed(detailed_var_event)
    simple_part = Formatter.format_simple(detailed_var_event)
    
    assert String.starts_with?(output, "#{inspect(@ts)} #{inspect(@pid_val)}")
    assert String.ends_with?(output, simple_part)
  end

  # --- Tests for format_json/1 ---
  # These tests assume Jason is available. If not, they will test the fallback.
  defp decode_json(json_string) do
    try do
      Jason.decode!(json_string)
    rescue
      UndefinedFunctionError -> # Jason not available
        # This indicates the fallback was triggered. We can't easily parse the fallback string robustly here,
        # so we'll check for the error message within it.
        %{"error" => "Jason library not configured for encoding"} 
    end
  end

  test "format_json/1 for :entry event" do
    json_output = Formatter.format_json(@detailed_entry_event)
    decoded = decode_json(json_output)

    if Map.has_key?(decoded, "error") do # Jason fallback was hit
      assert decoded["error"] == "Jason library not configured for encoding"
      assert String.contains?(json_output, "\"type\": \"entry\"") # Check data_preview part
      assert String.contains?(json_output, "\"module\": \"ElixirAST.Output.FormatterTest.MyApp.MyModule\"")
    else # Jason was available
      assert decoded["type"] == "entry"
      assert decoded["module"] == "ElixirAST.Output.FormatterTest.MyApp.MyModule" # Jason stringifies atoms
      assert decoded["function"] == "handle_call"
      assert decoded["arity"] == 3
      assert decoded["args"] == [1, "two", %{"key" => "val"}] # Jason stringifies map keys
      assert decoded["node_id"] == "ast_id_def_1"
      assert decoded["timestamp"] == inspect(@ts) # Serialized to string
      assert decoded["pid"] == inspect(@pid_val)   # Serialized to string
    end
  end

  test "format_json/1 for :exit event" do
    json_output = Formatter.format_json(@detailed_exit_event)
    decoded = decode_json(json_output)

    if Map.has_key?(decoded, "error") do
      assert decoded["error"] == "Jason library not configured for encoding"
      assert String.contains?(json_output, "\"type\": \"exit\"")
    else
      assert decoded["type"] == "exit"
      assert decoded["return_value"] == ["ok", "done"] # Tuple to list
      assert decoded["duration"] == 1234
      assert decoded["timestamp"] == inspect(@ts)
      assert decoded["pid"] == inspect(@pid_val)
    end
  end

  test "format_json/1 handles event with minimal fields" do
    minimal_event = %{type: :minimal, module: SomeMod, function: :func, arity: 0}
    json_output = Formatter.format_json(minimal_event)
    decoded = decode_json(json_output)

    if Map.has_key?(decoded, "error") do
      assert decoded["error"] == "Jason library not configured for encoding"
      assert String.contains?(json_output, "\"type\": \"minimal\"")
    else
      assert decoded["type"] == "minimal"
      assert decoded["module"] == "ElixirAST.Output.FormatterTest.SomeMod"
    end
  end
  
  test "format_json/1 for :var_capture event" do
    detailed_var_event = Map.merge(@var_capture_event, %{timestamp: @ts, pid: @pid_val})
    json_output = Formatter.format_json(detailed_var_event)
    decoded = decode_json(json_output)

    if Map.has_key?(decoded, "error") do
      assert decoded["error"] == "Jason library not configured for encoding"
      assert String.contains?(json_output, "\"type\": \"var_capture\"")
    else
      assert decoded["type"] == "var_capture"
      assert decoded["at"] == "entry"
      assert decoded["variables"] == %{"user" => %{"id" => 1, "name" => "Test"}}
    end
  end

  # --- General Tests (covered by specific type tests above) ---
  # "formatter handles various event types correctly" is covered by individual tests for each type.
  # "formatter handles missing optional fields in event data gracefully" is covered by format_simple and format_json minimal tests.
  end
end
