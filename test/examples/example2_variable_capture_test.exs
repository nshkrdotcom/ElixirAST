defmodule ElixirAST.Examples.VariableCaptureTest do
  use ExUnit.Case, async: true

  alias ElixirAST

  test "runs Example 2: Variable Capture as per PRD" do
    @moduledoc """
    Example 2: Variable Capture
    - Capture and log local variables during function execution.
    - Uses :detailed format for more context.
    - Captures specific variables before return and after a specific line.
    """

    source_code = """
    defmodule UserService do
      def process_user(user_data) do # line 2 in PRD, adjusted for 0-based in some systems or 1-based in others, using original line numbers for clarity
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
    |> ElixirAST.capture_variables([:validated_user, :enriched_user, :final_result], at: :before_return)
    |> ElixirAST.capture_variables([:validated_user], at: {:line, 3}) # Line number from PRD
    |> ElixirAST.output_to(:console)
    |> ElixirAST.format(:detailed)

    # {:ok, instrumented_ast} = ElixirAST.parse_and_transform(config, source_code)

    # Code compilation and execution of the instrumented module would occur here.
    # e.g., Code.compile_quoted(instrumented_ast, "example2_userservice.ex")
    #       module.process_user(%{name: "Alice", email: "alice@example.com"})

    # Placeholder assertions for expected output:
    # pending("assert console output contains '[<timestamp> <pid> ENTRY] ElixirAST.Transformed.UserService.process_user/1 ARGS: [%{...}]'")
    # pending("assert console output contains '[<timestamp> <pid> VAR_CAPTURE AT LINE 3] validated_user = %{...}'")
    # pending("assert console output contains '[<timestamp> <pid> VAR_CAPTURE BEFORE_RETURN] validated_user = %{...}, enriched_user = %{...}, final_result = %{...}'")
    # pending("assert console output contains '[<timestamp> <pid> EXIT]  ElixirAST.Transformed.UserService.process_user/1 RETURNED: {:ok, %{...}}'")

    flunk("Test not implemented: Example 2 - full execution and output verification")
  end
end
