defmodule ElixirAST.Api.PatternsTest do
  use ExUnit.Case, async: true

  alias ElixirAST.Api.Patterns # Corrected Alias

  # Helper to extract the {:def | :defp, ...} tuple from a quoted block
  defp get_def_node(quoted_code) do
    # For `defmodule M do def f(), do: ... end`, the AST is {:defmodule, _, [_, [do: {:__block__, _, [def_node]}]]} or similar
    # For a simple `def f(), do: ...`, it's often directly accessible.
    # A common way to get a single function def:
    # `quote do def my_fun(), do: :ok end` returns `{:def, meta, [{:my_fun, _, nil}, [do: :ok]]}`
    # If it's wrapped in a module for testing structure:
    # `quote do defmodule M do def f(), do: nil end end`
    # `|> elem(2) # body of defmodule`
    # `|> Enum.find(&match?({:def, _, _}, &1))` # find the def node
    # For simplicity, we'll quote individual functions.
    quoted_code
  end

  test "is_genserver_callback?/1 identifies GenServer callbacks" do
    assert Patterns.is_genserver_callback?(get_def_node(quote do def init(arg1), do: :ok end))
    assert Patterns.is_genserver_callback?(get_def_node(quote do def handle_call(msg, from, state), do: {:reply, :ok, state} end))
    assert Patterns.is_genserver_callback?(get_def_node(quote do def handle_cast(msg, state) when is_map(state), do: {:noreply, state} end))
    assert Patterns.is_genserver_callback?(get_def_node(quote do def handle_info(msg, state), do: {:noreply, state} end))
    assert Patterns.is_genserver_callback?(get_def_node(quote do def terminate(reason, state), do: :ok end))
    assert Patterns.is_genserver_callback?(get_def_node(quote do def code_change(old_vsn, state, extra), do: {:ok, state} end))
  end

  test "is_genserver_callback?/1 returns false for non-GenServer functions" do
    refute Patterns.is_genserver_callback?(get_def_node(quote do def my_init(arg1), do: :ok end)) # Wrong name
    refute Patterns.is_genserver_callback?(get_def_node(quote do def init(arg1, arg2), do: :ok end)) # Wrong arity
    refute Patterns.is_genserver_callback?(get_def_node(quote do defp init(arg1), do: :ok end)) # Not a def
    refute Patterns.is_genserver_callback?({:not_a_def, [], []}) # Not a function def
  end

  test "is_phoenix_action?/1 identifies Phoenix controller actions" do
    assert Patterns.is_phoenix_action?(get_def_node(quote do def index(conn, params), do: conn end))
    assert Patterns.is_phoenix_action?(get_def_node(quote do def show(conn, params) when not is_nil(params["id"]), do: conn end))
    assert Patterns.is_phoenix_action?(get_def_node(quote do def create(conn, params), do: conn end))
    assert Patterns.is_phoenix_action?(get_def_node(quote do def delete(conn, params), do: conn end))
  end

  test "is_phoenix_action?/1 returns false for non-Phoenix actions" do
    refute Patterns.is_phoenix_action?(get_def_node(quote do def my_index(conn, params), do: conn end))
    refute Patterns.is_phoenix_action?(get_def_node(quote do def index(conn, params, other), do: conn end)) # Wrong arity
    refute Patterns.is_phoenix_action?(get_def_node(quote do defp index(conn, params), do: conn end))
  end

  test "is_phoenix_live_view_callback?/1 identifies LiveView callbacks" do
    assert Patterns.is_phoenix_live_view_callback?(get_def_node(quote do def mount(params, session, socket), do: {:ok, socket} end))
    assert Patterns.is_phoenix_live_view_callback?(get_def_node(quote do def handle_params(params, uri, socket) when true, do: {:noreply, socket} end))
    assert Patterns.is_phoenix_live_view_callback?(get_def_node(quote do def handle_event(event, params, socket), do: {:noreply, socket} end))
    assert Patterns.is_phoenix_live_view_callback?(get_def_node(quote do def handle_info(msg, socket), do: {:noreply, socket} end)) # Overlaps GenServer
    assert Patterns.is_phoenix_live_view_callback?(get_def_node(quote do def render(assigns), do: :ok end))
    assert Patterns.is_phoenix_live_view_callback?(get_def_node(quote do def terminate(reason, socket), do: :ok end)) # Overlaps GenServer
  end

  test "is_phoenix_live_view_callback?/1 returns false for non-LiveView functions" do
    refute Patterns.is_phoenix_live_view_callback?(get_def_node(quote do def my_mount(p, s, so), do: {:ok, so} end))
    refute Patterns.is_phoenix_live_view_callback?(get_def_node(quote do def mount(p, s), do: {:ok, p} end)) # Wrong arity
  end

  test "is_public_function?/1 identifies public functions (def)" do
    assert Patterns.is_public_function?(get_def_node(quote do def my_func(), do: nil end))
    assert Patterns.is_public_function?(get_def_node(quote do def my_func_with_arg(arg), do: arg end))
  end

  test "is_public_function?/1 returns false for private functions (defp) and other nodes" do
    refute Patterns.is_public_function?(get_def_node(quote do defp my_private_func(), do: nil end))
    refute Patterns.is_public_function?({:some_other_node, [], []})
  end

  test "is_private_function?/1 identifies private functions (defp)" do
    assert Patterns.is_private_function?(get_def_node(quote do defp my_private_func(), do: nil end))
    assert Patterns.is_private_function?(get_def_node(quote do defp my_private_func_with_arg(arg), do: arg end))
  end

  test "is_private_function?/1 returns false for public functions (def) and other nodes" do
    refute Patterns.is_private_function?(get_def_node(quote do def my_public_func(), do: nil end))
    refute Patterns.is_private_function?({:some_other_node, [], []})
  end

  test "is_recursive_function?/1 identifies simple direct recursive functions" do
    recursive_def = get_def_node(quote do def fact(n) do if n <= 1, do: 1, else: n * fact(n-1) end end)
    assert Patterns.is_recursive_function?(recursive_def)

    recursive_defp = get_def_node(quote do defp helper(x) do helper(x-1) end end)
    assert Patterns.is_recursive_function?(recursive_defp)
  end

  test "is_recursive_function?/1 returns false for non-recursive functions" do
    non_recursive_def = get_def_node(quote do def not_fact(n), do: n end)
    refute Patterns.is_recursive_function?(non_recursive_def)
    
    # Calls another function with similar name/arity
    other_call_def = get_def_node(quote do def my_fun(a), do: other_fun(a) end)
    refute Patterns.is_recursive_function?(other_call_def)

    # Calls self with different arity (not direct recursion for this definition)
    diff_arity_call_def = get_def_node(quote do def my_fun(a), do: my_fun(a,1) end)
    refute Patterns.is_recursive_function?(diff_arity_call_def)
  end

  test "pattern matching functions handle various AST node types gracefully" do
    # Test with non-function AST nodes
    non_func_nodes = [
      quote(do: MyModule), # Alias
      quote(do: @my_attr 1), # Module attribute
      quote(do: x = 1), # Assignment
      quote(do: 1 + 2), # Expression
      :an_atom,
      123,
      "a string"
    ]

    for node <- non_func_nodes do
      refute Patterns.is_genserver_callback?(node), "Node: #{inspect node}"
      refute Patterns.is_phoenix_action?(node), "Node: #{inspect node}"
      refute Patterns.is_phoenix_live_view_callback?(node), "Node: #{inspect node}"
      refute Patterns.is_public_function?(node), "Node: #{inspect node}"
      refute Patterns.is_private_function?(node), "Node: #{inspect node}"
      refute Patterns.is_recursive_function?(node), "Node: #{inspect node}"
    end
  end
  
  # The test for "pattern definitions are well-structured" is less relevant here as patterns are functions,
  # not data structures to be validated. The tests above cover their behavior.
  # If patterns were data-driven, this test would be important.
  # For now, we can remove it or leave it as a conceptual note.
  # test "pattern definitions are well-structured (if applicable)" do
  #   # This test is conceptual as patterns are code-defined.
  #   :ok
  # end
  end
end
