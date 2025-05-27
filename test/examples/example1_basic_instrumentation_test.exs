defmodule ElixirAST.Examples.BasicInstrumentationTest do
  use ExUnit.Case, async: true

  alias ElixirAST # Assuming ElixirAST will be the main API module

  test "runs Example 1: Basic Instrumentation as per PRD" do
    @moduledoc """
    Example 1: Basic Function Instrumentation
    - Simple function entry/exit logging for all functions.
    - Logs arguments on entry and result on exit.
    - Uses :simple format.
    """

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

    # Transform (will not run successfully until ElixirAST is implemented)
    # {:ok, instrumented_ast} = ElixirAST.parse_and_transform(config, source_code)

    # Code compilation and execution of the instrumented module would occur here.
    # e.g., Code.compile_quoted(instrumented_ast, "example1_calculator.ex")
    #       module.process(10)
    #       module.add(5, 3)

    # Placeholder assertions for expected output:
    # pending("assert console output contains '[ENTRY] ElixirAST.Transformed.Calculator.process/1 ARGS: [10]'")
    # pending("assert console output contains '[ENTRY] ElixirAST.Transformed.Calculator.multiply/2 ARGS: [10, 2]'")
    # pending("assert console output contains '[EXIT]  ElixirAST.Transformed.Calculator.multiply/2 RETURNED: 20'")
    # pending("assert console output contains '[ENTRY] ElixirAST.Transformed.Calculator.add/2 ARGS: [20, 5]'")
    # pending("assert console output contains '[EXIT]  ElixirAST.Transformed.Calculator.add/2 RETURNED: 25'")
    # pending("assert console output contains '[EXIT]  ElixirAST.Transformed.Calculator.process/1 RETURNED: 25'")
    # pending("assert console output contains '[ENTRY] ElixirAST.Transformed.Calculator.add/2 ARGS: [5, 3]'")
    # pending("assert console output contains '[EXIT]  ElixirAST.Transformed.Calculator.add/2 RETURNED: 8'")

    flunk("Test not implemented: Example 1 - full execution and output verification")
  end
end
