defmodule ElixirAST.Core.Parser do
  def parse(source_code) do
    case Code.string_to_quoted(source_code) do
      {:ok, ast} ->
        # Rudimentary node ID assignment for now - just adds one to the top-level
        # More sophisticated ID assignment will be needed later.
                metadata = elem(ast, 1)
                new_metadata = Keyword.put(metadata, :elixir_ast_node_id, "node_0")
                ast_with_id = put_elem(ast, 1, new_metadata)
        {:ok, ast_with_id}
      {:error, _reason} = error ->
        error
    end
  end
end
