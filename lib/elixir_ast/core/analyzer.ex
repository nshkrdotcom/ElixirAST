defmodule ElixirAST.Core.Analyzer do
  @moduledoc """
  Internal. Code analysis and pattern detection.
  """

  alias ElixirAST.Api.Patterns

  @type ast_node() :: term() # From ElixirAST module, assuming it's defined there or globally

  @spec analyze(ast_node()) :: map()
  def analyze(ast) do
    initial_acc = %{
      functions: [],
      node_count: 0,
      # patterns_detected will be added after traversal
      # complexity_estimate will be added after traversal
    }

    # Pre-order traversal function
    pre_fn = fn
      # Match function definitions (def, defp, defmacro, defmacrop)
      ({type, meta, [name_arity_list | body_clauses]} = node, acc)
      when type in [:def, :defp, :defmacro, :defmacrop] and is_list(name_arity_list) and is_list(body_clauses) ->
        # This structure is more like `{:def, meta, [{name, meta_name, args_ctx}, [do: ...]]}`
        # The actual name/arity extraction needs to handle the specific AST structure for function heads.
        # Let's refine based on common function definition structure:
        # e.g., `{:def, meta, [{:my_fun, fn_meta, args_ast_list}, [do: block]]}`
        # or `{:def, meta, [{:my_fun, fn_meta, args_ast_list} | _other_clauses_if_any]}` - this needs care.
        # For simplicity, we assume the first element of the third part of the tuple is the primary head.
        
        # Default values
        func_name = :unknown
        func_arity = -1
        line = Keyword.get(meta, :line, -1)
        node_id = Keyword.get(meta, :elixir_ast_node_id)

        # Attempt to extract name and arity from common structures
        case name_arity_list do
          {n, _fn_meta, a_list} when is_atom(n) and is_list(a_list) -> # Standard {name, meta, args}
            func_name = n
            func_arity = length(a_list)
          {n, _fn_meta, nil} when is_atom(n) -> # {name, meta, nil} for zero-arity without explicit []
            func_name = n
            func_arity = 0
          # Handle `def my_fun(arg1) when guard1 do ... end`
          # AST: `{:def, meta, [{:when, meta_when, [{:my_fun, meta_fun, args}, guards]}, body]}`
          {:when, _when_meta, [{n, _fn_meta, a_list}, _guards]} when is_atom(n) and is_list(a_list) ->
            func_name = n
            func_arity = length(a_list)
          {:when, _when_meta, [{n, _fn_meta, nil}, _guards]} when is_atom(n) -> # with guard, zero arity
            func_name = n
            func_arity = 0
          _ ->
            # Could be a multi-clause function definition where name_arity_list is actually a list of clauses.
            # This simple extraction won't cover all cases perfectly, especially complex multi-clause heads.
            # For now, we log it as unknown or attempt a best guess if possible.
            # This part requires more robust AST inspection for multi-clause functions.
            # For MVP, we focus on the most common single-clause structure.
            :ok # func_name and func_arity remain default
        end
        
        func_info = %{
          name: func_name,
          arity: func_arity,
          line: line,
          type: type,
          node_id: node_id
        }
        
        new_acc = %{acc | 
          functions: [func_info | acc.functions], 
          node_count: acc.node_count + 1
        }
        {node, new_acc}

      (node, acc) ->
        {node, %{acc | node_count: acc.node_count + 1}}
    end

    # Post-order traversal function (not strictly needed for this analysis if pre_fn does all)
    post_fn = fn node, acc -> {node, acc} end

    {_processed_ast, analysis_acc} = Macro.traverse(ast, initial_acc, pre_fn, post_fn)

    # Determine complexity (simple heuristic)
    complexity = 
      cond do
        analysis_acc.node_count > 200 or length(analysis_acc.functions) > 20 -> :high
        analysis_acc.node_count > 75 or length(analysis_acc.functions) > 7 -> :medium
        analysis_acc.node_count > 0 -> :low
        true -> :not_calculated # Or :low if node_count is 0
      end

    # Detect patterns
    all_known_patterns = [
      :genserver_callbacks, :phoenix_actions, :phoenix_live_view_callbacks,
      :public_functions, :private_functions, :recursive_functions
    ]
    detected_patterns_list = detect_patterns(ast, all_known_patterns)
    
    %{
      functions: Enum.reverse(analysis_acc.functions), # Reverse to maintain source order
      node_count: analysis_acc.node_count,
      patterns_detected: detected_patterns_list,
      complexity_estimate: complexity
    }
  end


  @spec detect_patterns(ast_node(), [atom()]) :: [atom()]
  def detect_patterns(ast, pattern_targets) do
    # Collect all function definition nodes from the AST first
    # The pre_fn for collecting function nodes needs to be careful not to modify the accumulator for other nodes.
    # It should only add to the list if it's a function node.
    collect_fns_pre = fn
      ({type, _, _} = func_node, acc_list) when type in [:def, :defp, :defmacro, :defmacrop] ->
        {func_node, [func_node | acc_list]} # Return node unchanged, add to accumulator
      (other_node, acc_list) ->
        {other_node, acc_list} # Return node unchanged, pass accumulator
    end
    
    # The post_fn is not strictly necessary if pre_fn does all collection.
    collect_fns_post = fn node, acc -> {node, acc} end

    all_function_nodes = 
      Macro.traverse(ast, [], collect_fns_pre, collect_fns_post)
      |> elem(1) # Get the accumulated list of function nodes
      |> Enum.reverse() # Maintain source order

    Enum.reduce(pattern_targets, MapSet.new(), fn pattern_atom, detected_set ->
      Enum.reduce(all_function_nodes, detected_set, fn func_node, current_set ->
        matches? =
          case pattern_atom do
            :genserver_callbacks -> Patterns.is_genserver_callback?(func_node)
            :phoenix_actions -> Patterns.is_phoenix_action?(func_node)
            :phoenix_live_view_callbacks -> Patterns.is_phoenix_live_view_callback?(func_node)
            :public_functions -> Patterns.is_public_function?(func_node)
            :private_functions -> Patterns.is_private_function?(func_node)
            :recursive_functions -> Patterns.is_recursive_function?(func_node)
            _ -> false # Unknown pattern, ignore
          end
        if matches?, do: MapSet.put(current_set, pattern_atom), else: current_set
      end)
    end)
    |> Enum.to_list()
    |> Enum.sort()
  end
end
