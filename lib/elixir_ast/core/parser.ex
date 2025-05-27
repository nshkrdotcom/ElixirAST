defmodule ElixirAST.Core.Parser do
  @moduledoc """
  Internal. AST parsing with unique node identification.
  Implements F1 from PRD.
  """

  @doc """
  Parses Elixir source code into an AST and assigns unique node IDs.
  Node IDs are stored in the metadata of AST nodes under the key `:elixir_ast_node_id`.
  Handles major Elixir constructs.
  """
  @spec parse(binary()) :: {:ok, ElixirAST.ast_node()} | {:error, term()}
  def parse(source_code) when is_binary(source_code) do
    # Implementation using Code.string_to_quoted/2 and assign_node_ids/1
    with {:ok, ast} <- Code.string_to_quoted(source_code, PWD: false, columns: true, token_metadata: true), # PWD: false for determinism if paths are involved
         {:ok, ast_with_ids} <- assign_node_ids(ast) do
      {:ok, ast_with_ids}
    else
      {:error, error_details} -> {:error, error_details} # Pass through parsing errors
      other_error -> other_error # Pass through assign_node_ids errors
    end
  end

  @doc """
  Assigns unique, stable, and deterministic node IDs to relevant AST nodes.
  Node IDs are binary strings, generated based on node structure and position.
  This function is typically called by `parse/1`.
  """
  @spec assign_node_ids(ElixirAST.ast_node()) :: {:ok, ElixirAST.ast_node()} | {:error, term()}
  def assign_node_ids(ast) do
    initial_counter = 0

    pre_fn = fn
      # Clause for typical {name, meta, children} nodes that should get an ID
      {name, meta, children} = current_node, counter when is_atom(name) and is_list(meta) ->
        node_id = generate_node_id(counter, current_node)
        new_meta = Keyword.put(meta, :elixir_ast_node_id, node_id)
        {{name, new_meta, children}, counter + 1}

      # Clause for 2-tuple nodes like {meta, value} where meta is a list
      {meta, value} = current_node, counter when is_list(meta) and not is_tuple(value) and not is_list(value) ->
        # This clause is for nodes where `meta` is the primary metadata list, and value is a literal.
        # Excludes cases where `value` itself is a tuple or list that should be traversed.
        node_id = generate_node_id(counter, current_node)
        new_meta = Keyword.put(meta, :elixir_ast_node_id, node_id)
        {{new_meta, value}, counter + 1}

      # Default clause for nodes that do not get an ID or for structures that should be traversed but not IDed themselves.
      current_node, counter ->
        {current_node, counter}
    end

    post_fn = fn node, acc -> {node, acc} end

    {processed_ast, _final_counter} = Macro.traverse(ast, initial_counter, pre_fn, post_fn)
    {:ok, processed_ast}
  end

  # Generates a node ID based on a sequential counter and node structure.
  defp generate_node_id(sequential_id, node_structure) do
    node_type_indicator =
      case node_structure do
        {name, meta, _children} when is_atom(name) and is_list(meta) -> Atom.to_string(name)
        {meta, val} when is_list(meta) ->
          cond do
            is_atom(val) -> Atom.to_string(val) # e.g. an alias
            is_list(val) -> "list" # e.g. a charlist or list of expressions (might need care if children are expressions)
            is_tuple(val) -> "tuple" # A literal tuple like {1,2} inside {meta, {1,2}}
            is_map(val) -> "map"
            is_binary(val) -> "string"
            is_integer(val) -> "integer"
            is_float(val) -> "float"
            is_boolean(val) -> "boolean"
            true -> "literal"
          end
        {:__block__, _, _} -> "block"
        {:__aliases__, _, _} -> "aliases"
        {:=, _, _} -> "assign"
        {'.', _, [_, _]} -> "dot" # Remote call
        # Add more specific common node types if desired
        # This case is for bare literals or other structures not fitting the above.
        # If node_structure is a simple literal (e.g. an atom, integer), it won't be caught by above.
        # Macro.traverse usually passes these as-is, so they wouldn't typically reach pre_fn unless wrapped.
        _ -> "node"
      end
    "ast_id_#{node_type_indicator}_#{sequential_id}"
  end
end
