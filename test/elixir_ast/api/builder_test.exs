defmodule ElixirAST.Api.BuilderTest do
  use ExUnit.Case, async: true

  alias ElixirAST.Api.Builder # Correct alias

  test "validate/1 returns :ok for a valid default configuration" do
    config = %Builder{}
    assert Builder.validate(config) == :ok
  end

  test "validate/1 returns :ok for a configuration with various options set correctly" do
    config = %Builder{
      function_target_spec: {:instrument, {:only, [:my_fun, {:other_fun, 2}]}},
      pattern_targets: [:genserver_callbacks],
      log_function_entry_exit_opts: [capture_args: true, capture_return: false, log_duration: true],
      variables_to_capture: %{entry: [:var1, :var2], {:line, 10} => [:var3]},
      expressions_to_track: [{quote(do: a + b), [log_intermediate: true]}],
      custom_injections: %{
        before_return: [{quote(do: IO.puts("ret")), [context_vars: [:a]]}],
        on_error: [{quote(do: IO.puts("err")), []}]
      },
      output_target: :console,
      output_format: :detailed,
      verbose_mode: true
    }
    assert Builder.validate(config) == :ok
  end

  # --- Output Configuration ---
  test "validate/1 returns error for invalid output_target" do
    config = %Builder{output_target: :file}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_output_target)
    assert reasons[:invalid_output_target] == :file # Updated to match actual error format
  end

  test "validate/1 returns error for invalid output_format" do
    config = %Builder{output_format: :xml}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_output_format)
    assert reasons[:invalid_output_format] == :xml # Updated
  end

  # --- Function Targeting ---
  test "validate/1 returns error for invalid function_target_spec type" do
    config = %Builder{function_target_spec: :all_functions} # Not a tuple like {:instrument, :all}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_function_target_spec_type)
  end

  test "validate/1 returns error for invalid function_target_spec atom value" do
    config = %Builder{function_target_spec: {:instrument, :all_func}} # :all_func is not :all, :public, or :private
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_function_target_spec_value)
  end
  
  test "validate/1 returns error for invalid function_target_spec :only list content" do
    config = %Builder{function_target_spec: {:instrument, {:only, ["not_an_atom_or_tuple"]}}}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_function_target_spec_list)
  end

  test "validate/1 returns error for invalid function_target_spec :except list content" do
    config = %Builder{function_target_spec: {:instrument, {:except, [{:valid, 1}, 123]}}} # 123 is invalid
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_function_target_spec_list)
  end

  # --- Pattern Targeting ---
  test "validate/1 returns error for unknown pattern_targets" do
    config = %Builder{pattern_targets: [:genserver_callbacks, :unknown_pattern]}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :unknown_pattern_target)
    assert reasons[:unknown_pattern_target] == :unknown_pattern # Updated
  end

  # --- Instrumentation Actions ---
  test "validate/1 returns error for invalid log_function_entry_exit_opts key" do
    config = %Builder{log_function_entry_exit_opts: [capture_args: true, invalid_key: false]}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_log_entry_exit_opt_key)
  end

  test "validate/1 returns error for invalid log_function_entry_exit_opts value type" do
    config = %Builder{log_function_entry_exit_opts: [capture_args: "not_a_boolean"]}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_log_entry_exit_opt_value)
  end

  test "validate/1 returns error for invalid variables_to_capture key (capture point)" do
    config = %Builder{variables_to_capture: %{invalid_point: [:var1]}}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_capture_point)
  end

  test "validate/1 returns error for invalid variables_to_capture value (not list of atoms)" do
    config = %Builder{variables_to_capture: %{entry: ["not_an_atom"]}}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_variables_for_capture)
  end

  test "validate/1 returns error for invalid expressions_to_track structure (entry not a tuple)" do
    config = %Builder{expressions_to_track: [quote(do: a), [log_intermediate: false]]} # Entry is not {expr, opts}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_expression_tracking_entry)
  end

  test "validate/1 returns error for invalid expressions_to_track option value" do
    config = %Builder{expressions_to_track: [{quote(do: a), [log_intermediate: "yes"]}]}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_track_expression_opt_value)
  end

  test "validate/1 returns error for invalid custom_injections key (injection point)" do
    config = %Builder{custom_injections: %{invalid_point: [{quote(do: x), []}]}}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_injection_point)
  end

  test "validate/1 returns error for invalid custom_injections value structure (entry not {code, opts})" do
    config = %Builder{custom_injections: %{before_return: [quote(do: x)]}} # Not a list of {code, opts}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_custom_injection_format)
  end
  
  test "validate/1 returns error for invalid custom_injections context_vars (not list of atoms)" do
    config = %Builder{custom_injections: %{before_return: [{quote(do: x), [context_vars: ["not_atom"]]}]}}
    assert {:error, reasons} = Builder.validate(config)
    assert Keyword.has_key?(reasons, :invalid_custom_injection_format) # This error is caught by the format check
  end

  test "validate/1 returns error for multiple validation issues" do
    config = %Builder{
      output_target: :file,
      output_format: :xml,
      pattern_targets: [:invalid_one, :another_invalid]
    }
    assert {:error, reasons} = Builder.validate(config)
    assert length(Keyword.keys(reasons)) >= 3 # Check for multiple errors
    assert Keyword.has_key?(reasons, :invalid_output_target)
    assert Keyword.has_key?(reasons, :invalid_output_format)
    assert Keyword.has_key?(reasons, :unknown_pattern_target) # Will report first unknown pattern
  end
end
