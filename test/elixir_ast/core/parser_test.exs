defmodule ElixirAST.Core.ParserTest do
  use ExUnit.Case, async: true

  alias ElixirAST.Core.Parser

  # Helper function to collect node IDs from an AST
  defp collect_node_ids(ast) do
    initial_acc = []
    # Pre-order traversal: process node then children
    pre_fn = fn 
      node_ast, acc ->
        meta = 
          cond do
            # Standard {name, meta, children} or {name, meta, nil}
            is_tuple(node_ast) and tuple_size(node_ast) == 3 and elem(node_ast, 1) |> is_list() -> elem(node_ast, 1)
            # {meta, value} nodes
            is_tuple(node_ast) and tuple_size(node_ast) == 2 and elem(node_ast, 0) |> is_list() -> elem(node_ast, 0)
            true -> []
          end
        
        id = Keyword.get(meta, :elixir_ast_node_id)
        new_acc = if id, do: [id | acc], else: acc
        {node_ast, new_acc} # Return node unchanged, pass accumulator
    end
    # Post-order traversal: process children then node (not needed if pre_fn does all work)
    post_fn = fn node_ast, acc -> {node_ast, acc} end

    Macro.traverse(ast, initial_acc, pre_fn, post_fn) |> elem(1) |> Enum.reverse()
  end

  test "parse/1 successfully parses valid Elixir source code string" do
    source = "defmodule Sample do def hello, do: :world end"
    assert {:ok, ast} = Parser.parse(source)
    # Check a basic AST structure. The actual AST is wrapped.
    # Example: `{:defmodule, [line: 1, elixir_ast_node_id: "ast_id_defmodule_0"], [...]}`
    assert match?({:defmodule, meta, _}, ast) when is_list(meta)
    assert Keyword.has_key?(meta, :elixir_ast_node_id)
  end

  test "parse/1 returns an error for invalid Elixir source code" do
    source = "defmodule Sample do def hello, do: end" # missing value after do:
    assert {:error, _reason} = Parser.parse(source)
  end

  test "parse/1 assigns node IDs to AST nodes" do
    source = "x = 1 + 2"
    assert {:ok, ast} = Parser.parse(source)
    
    ids = collect_node_ids(ast)
    assert Enum.any?(ids), "Expected some node IDs to be present"
    
    # Check format of all collected IDs
    Enum.each(ids, fn id ->
      assert is_binary(id)
      assert Regex.match?(~r/^ast_id_[a-zA-Z0-9_]+_\d+$/, id), "ID format mismatch for: #{id}"
    end)

    # A more specific check on a known node (e.g., the assignment)
    # The AST for "x = 1 + 2" is complex.
    # `{{:x, [line: 1, elixir_ast_node_id: "..."], nil}, [line: 1, elixir_ast_node_id: "..."], ...}`
    # Let's check the top-level expression wrapper if any, or a known part.
    # The direct result of `Code.string_to_quoted` for "x = 1 + 2" is:
    # `{:__block__, [line: 1], [{:=, [line: 1], [{:x, [line: 1], nil}, {:+, [line: 1], [1, 2]}]}]}`
    # After ID assignment, it should have elixir_ast_node_id in metadata.

    assert match?({:__block__, meta_block, _}, ast) when is_list(meta_block)
    assert Keyword.get(meta_block, :elixir_ast_node_id) =~ ~r/^ast_id___block__\d+$/
    
    # Traverse to find the assignment operator :=
    # This is a simplified traversal for this specific test.
    {_block_name, _block_meta, [{assign_op, assign_meta, _assign_children}]} = ast
    assert assign_op == :=
    assert Keyword.get(assign_meta, :elixir_ast_node_id) =~ ~r/^ast_id_assign_\d+$/
  end

  # Test for assign_node_ids/1 directly
  test "assign_node_ids/1 correctly assigns IDs to a raw AST" do
    raw_ast = {:defmodule, [line: 1],
      [
        {:__aliases__, [line: 1], [:MyModule]},
        [
          do: {:def, [line: 2],
           [
             {:hello, [line: 2], nil},
             [do: :world]
           ]}
        ]
      ]}
    
    assert {:ok, ast_with_ids} = Parser.assign_node_ids(raw_ast)
    ids = collect_node_ids(ast_with_ids)
    
    assert Enum.count(ids) > 3, "Expected multiple node IDs" # defmodule, __aliases__, def, hello, etc.
    Enum.each(ids, fn id ->
      assert is_binary(id)
      assert Regex.match?(~r/^ast_id_[a-zA-Z0-9_]+_\d+$/, id)
    end)
  end
  
  test "assign_node_ids/1 ensures node IDs are unique within a single AST" do
    source = """
    defmodule ComplexSample do
      def func1(a) do
        b = a + 10
        c = b * 2
        if c > 50 do
          :greater
        else
          :smaller_or_equal
        end
      end
      defp func2(x), do: x - 1
    end
    """
    assert {:ok, ast} = Parser.parse(source)
    ids = collect_node_ids(ast)
    
    assert Enum.count(ids) > 0, "No node IDs collected"
    assert length(ids) == length(Enum.uniq(ids)), "Node IDs are not unique"
  end

  test "assign_node_ids/1 produces stable and deterministic IDs for the same source" do
    source = "a = (b + c) * d"
    assert {:ok, ast1} = Parser.parse(source)
    assert {:ok, ast2} = Parser.parse(source)
    assert ast1 == ast2, "ASTs generated from the same source should be identical (including node IDs)"
  end

  # The "handles all major Elixir constructs" test is broad.
  # We can add a more complex example to ensure parsing and ID assignment don't crash.
  test "parse/1 handles a variety of Elixir constructs" do
    source = """
    defmodule MyMod do
      @my_attr :some_value

      defstruct name: "Default", age: 0

      def public_func(x, y \\ :default) do
        cond do
          x > y -> :gt
          x < y -> :lt
          true -> :eq
        end
        |> case do
          :gt -> handle_greater(x)
          :lt -> handle_lesser(y)
          :eq -> {:equal, MyMod.Helper.transform(x)}
        end
      end

      defp handle_greater(val) do
        for i <- 1..val, i > 10, do: i * @my_attr_val \\ 2
      end

      defp handle_lesser(val) do
        try do
          {:ok, val}
        rescue
          _e -> {:error, :failed}
        catch
          :exit, reason -> {:exit, reason}
        end
      end

      defmodule Helper do
        def transform(data), do: data # simplified
      end
    end
    """
    assert {:ok, ast} = Parser.parse(source)
    ids = collect_node_ids(ast)
    assert Enum.count(ids) > 10 # Expect many nodes in this complex example
    assert length(ids) == length(Enum.uniq(ids))
  end
end
