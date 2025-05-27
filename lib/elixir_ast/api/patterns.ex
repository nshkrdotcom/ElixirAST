defmodule ElixirAST.Api.Patterns do
  @moduledoc """
  Internal. Defines and matches common Elixir code patterns.
  These helpers are typically used by the Analyzer to identify specific types of functions.
  """

  # --- GenServer Callbacks ---

  @doc """
  Checks if the given AST node represents a common GenServer callback.
  """
  @spec is_genserver_callback?(ElixirAST.ast_node()) :: boolean()
  def is_genserver_callback?({:def, _meta, [name, args_node, _body]}) when is_atom(name) and is_list(args_node) do
    do_is_genserver_callback?(name, length(args_node))
  end
  def is_genserver_callback?({:def, _meta, [name, {:when, _, [args_node, _guards]}, _body]}) when is_atom(name) and is_list(args_node) do
    # Handle functions with guards by extracting args from the 'when' clause's args_node
    do_is_genserver_callback?(name, length(args_node))
  end
  def is_genserver_callback?(_), do: false

  defp do_is_genserver_callback?(:init, 1), do: true
  defp do_is_genserver_callback?(:handle_call, 3), do: true
  defp do_is_genserver_callback?(:handle_cast, 2), do: true
  defp do_is_genserver_callback?(:handle_info, 2), do: true
  defp do_is_genserver_callback?(:terminate, 2), do: true
  defp do_is_genserver_callback?(:code_change, 3), do: true
  defp do_is_genserver_callback?(_, _), do: false

  # --- Phoenix Controller Actions ---

  @doc """
  Checks if the given AST node represents a common Phoenix controller action.
  """
  @spec is_phoenix_action?(ElixirAST.ast_node()) :: boolean()
  def is_phoenix_action?({:def, _meta, [name, args_node, _body]}) when is_atom(name) and is_list(args_node) do
    do_is_phoenix_action?(name, length(args_node))
  end
  def is_phoenix_action?({:def, _meta, [name, {:when, _, [args_node, _guards]}, _body]}) when is_atom(name) and is_list(args_node) do
    do_is_phoenix_action?(name, length(args_node))
  end
  def is_phoenix_action?(_), do: false

  defp do_is_phoenix_action?(:index, 2), do: true
  defp do_is_phoenix_action?(:show, 2), do: true
  defp do_is_phoenix_action?(:new, 2), do: true
  defp do_is_phoenix_action?(:create, 2), do: true
  defp do_is_phoenix_action?(:edit, 2), do: true
  defp do_is_phoenix_action?(:update, 2), do: true
  defp do_is_phoenix_action?(:delete, 2), do: true
  defp do_is_phoenix_action?(_, _), do: false

  # --- Phoenix LiveView Callbacks ---

  @doc """
  Checks if the given AST node represents a common Phoenix LiveView callback.
  """
  @spec is_phoenix_live_view_callback?(ElixirAST.ast_node()) :: boolean()
  def is_phoenix_live_view_callback?({:def, _meta, [name, args_node, _body]}) when is_atom(name) and is_list(args_node) do
    do_is_phoenix_live_view_callback?(name, length(args_node))
  end
  def is_phoenix_live_view_callback?({:def, _meta, [name, {:when, _, [args_node, _guards]}, _body]}) when is_atom(name) and is_list(args_node) do
    do_is_phoenix_live_view_callback?(name, length(args_node))
  end
  def is_phoenix_live_view_callback?(_), do: false

  defp do_is_phoenix_live_view_callback?(:mount, 3), do: true
  defp do_is_phoenix_live_view_callback?(:handle_params, 3), do: true
  defp do_is_phoenix_live_view_callback?(:handle_event, 3), do: true
  defp do_is_phoenix_live_view_callback?(:handle_info, 2), do: true # Overlaps with GenServer
  defp do_is_phoenix_live_view_callback?(:render, 1), do: true
  defp do_is_phoenix_live_view_callback?(:terminate, 2), do: true # Overlaps with GenServer
  defp do_is_phoenix_live_view_callback?(_, _), do: false

  # --- Public/Private Function Checks ---

  @doc """
  Checks if the AST node is a public function definition (`def`).
  """
  @spec is_public_function?(ElixirAST.ast_node()) :: boolean()
  def is_public_function?({:def, _meta, _signature_and_body}), do: true
  def is_public_function?(_), do: false

  @doc """
  Checks if the AST node is a private function definition (`defp`).
  """
  @spec is_private_function?(ElixirAST.ast_node()) :: boolean()
  def is_private_function?({:defp, _meta, _signature_and_body}), do: true
  def is_private_function?(_), do: false

  # --- Recursive Function Check (Placeholder) ---

  @doc """
  Checks if the function definition AST node appears to be recursive.
  This is a simplified check for direct self-calls.
  """
  @spec is_recursive_function?(ElixirAST.ast_node()) :: boolean()
  def is_recursive_function?({:defp, _meta, [name | args_node], body_expr}) when is_atom(name) and is_list(args_node) do
    arity = length(args_node)
    do_is_recursive?(name, arity, body_expr)
  end
  def is_recursive_function?({:def, _meta, [name | args_node], body_expr}) when is_atom(name) and is_list(args_node) do
    arity = length(args_node)
    do_is_recursive?(name, arity, body_expr)
  end
  def is_recursive_function?(_), do: false

  defp do_is_recursive?(function_name, arity, body_expr) do
    # Simplified check using Macro.traverse to find direct calls to itself.
    # acc is initially false, set to true if a recursive call is found.
    pre_fn = fn
      # Check for a direct call: {^function_name, _call_meta, call_args_list}
      {^function_name, _call_meta, call_args_list}, acc when is_list(call_args_list) ->
        if length(call_args_list) == arity do
          {{function_name, _call_meta, call_args_list}, true} # Found recursive call, set acc to true
        else
          {{function_name, _call_meta, call_args_list}, acc} # Arity mismatch, not this function
        end
      # For calls inside blocks or other structures, just pass through the node and accumulator
      node, acc -> {node, acc}
    end
    # Post-order function is not strictly needed if pre_fn does all the work and we stop early.
    # However, traverse expects both.
    post_fn = fn node, acc -> {node, acc} end

    Macro.traverse(body_expr, false, pre_fn, post_fn) |> elem(1) # Get the final accumulator
  end
end
