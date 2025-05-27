defmodule ElixirAST.Examples.GenServerInstrumentationTest do
  use ExUnit.Case, async: true

  alias ElixirAST

  test "runs Example 3: GenServer Instrumentation as per PRD" do
    @moduledoc """
    Example 3: GenServer Pattern Instrumentation
    - Automatically instrument GenServer callbacks with state tracking.
    - Uses structured JSON format for output.
    - Targets GenServer callbacks using target_pattern.
    - Captures state variables at entry and before return.
    """

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
    |> ElixirAST.instrument_functions(:all, log_entry_exit: [capture_args: true, capture_return: true])
    |> ElixirAST.capture_variables([:state, :new_state], at: :entry)
    |> ElixirAST.capture_variables([:state, :new_state], at: :before_return)
    |> ElixirAST.output_to(:console)
    |> ElixirAST.format(:json)

    # {:ok, instrumented_ast} = ElixirAST.parse_and_transform(config, source_code)

    # Code compilation and execution of the instrumented module would occur here.
    # e.g., Code.compile_quoted(instrumented_ast, "example3_counterserver.ex")
    #       {:ok, pid} = module.start_link(10)
    #       module.increment(pid, 5)
    #       module.get_value(pid)
    #       GenServer.cast(pid, :reset)
    #       GenServer.stop(pid)

    # Placeholder assertions for expected output (JSON lines):
    # pending("assert console output contains JSON for [ENTRY] CounterServer.init/1")
    # pending("assert console output contains JSON for VAR_CAPTURE AT ENTRY for CounterServer.init/1 (state)")
    # pending("assert console output contains JSON for [EXIT] CounterServer.init/1")
    # pending("assert console output contains JSON for [ENTRY] CounterServer.handle_call/3 ({:increment, amount})")
    # pending("assert console output contains JSON for VAR_CAPTURE AT ENTRY for CounterServer.handle_call/3 (state)")
    # pending("assert console output contains JSON for VAR_CAPTURE BEFORE_RETURN for CounterServer.handle_call/3 (new_state)")
    # pending("assert console output contains JSON for [EXIT] CounterServer.handle_call/3 ({:increment, amount})")
    # ... and so on for other calls.

    flunk("Test not implemented: Example 3 - full execution and output verification")
  end
end
