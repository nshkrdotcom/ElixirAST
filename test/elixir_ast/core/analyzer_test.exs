defmodule ElixirAST.Core.AnalyzerTest do
  use ExUnit.Case, async: true

  alias ElixirAST.Core.Analyzer
  alias ElixirAST.Core.Parser # For parsing source into AST

  # Helper to get a clean AST for a single function definition for detect_patterns tests
  defp get_function_ast(code_string) do
    {:ok, {:defmodule, _, [_, [do: {:__block__, _, [func_ast]}]]}} = Parser.parse("defmodule Tmp do\n#{code_string}\nend")
    func_ast
  end

  # --- Tests for analyze/1 ---
  test "analyze/1 identifies function definitions, types, and basic details" do
    source = """
    defmodule MyMod do
      def pub_fun(a), do: a               # line 2
      defp priv_fun(b, c), do: {b, c}    # line 3
      defmacro pub_macro(x), do: x        # line 4
      defmacrop priv_macrop(y), do: y   # line 5
    end
    """
    {:ok, ast} = Parser.parse(source)
    report = Analyzer.analyze(ast)

    assert length(report.functions) == 4

    pub_fun = Enum.find(report.functions, &(&1.name == :pub_fun))
    assert pub_fun.arity == 1
    assert pub_fun.type == :def
    assert pub_fun.line == 2 # Assuming line numbers are correctly parsed by Core.Parser
    assert is_binary(pub_fun.node_id)

    priv_fun = Enum.find(report.functions, &(&1.name == :priv_fun))
    assert priv_fun.arity == 2
    assert priv_fun.type == :defp
    assert priv_fun.line == 3
    assert is_binary(priv_fun.node_id)

    pub_macro = Enum.find(report.functions, &(&1.name == :pub_macro))
    assert pub_macro.arity == 1
    assert pub_macro.type == :defmacro
    assert pub_macro.line == 4
    assert is_binary(pub_macro.node_id)
    
    priv_macrop = Enum.find(report.functions, &(&1.name == :priv_macrop))
    assert priv_macrop.arity == 1
    assert priv_macrop.type == :defmacrop
    assert priv_macrop.line == 5
    assert is_binary(priv_macrop.node_id)
  end

  test "analyze/1 provides node_count and complexity_estimate" do
    source = "defmodule Simple do def f, do: 1; def g, do: 2; end" # Relatively small
    {:ok, ast_simple} = Parser.parse(source)
    report_simple = Analyzer.analyze(ast_simple)
    assert report_simple.node_count > 0
    assert report_simple.complexity_estimate == :low

    # A more complex source might yield :medium or :high, but exact threshold is heuristic
    source_complex = """
    defmodule Complex do
      for i <- 1..10 do
        def unquote(:"fun_#{i}")(a) do
          a + unquote(i) |> Enum.sum() |> Kernel.trunc()
        end
      end
      def another(a,b,c,d,e,f,g,h,i,j) do
        {a,b,c,d,e,f,g,h,i,j}
      end
    end
    """
    {:ok, ast_complex} = Parser.parse(source_complex)
    report_complex = Analyzer.analyze(ast_complex)
    assert report_complex.node_count > report_simple.node_count
    assert Enum.member?([:low, :medium, :high], report_complex.complexity_estimate)
  end

  test "analyze/1 returns a map with expected analysis report structure" do
    source = "defmodule EmptyModule, do: nil"
    {:ok, ast} = Parser.parse(source)
    report = Analyzer.analyze(ast)

    assert Map.has_key?(report, :functions)
    assert Map.has_key?(report, :node_count)
    assert Map.has_key?(report, :patterns_detected)
    assert Map.has_key?(report, :complexity_estimate)
    assert is_list(report.functions)
    assert is_integer(report.node_count)
    assert is_list(report.patterns_detected)
    assert is_atom(report.complexity_estimate)
  end
  
  test "analyze/1 correctly detects patterns for a mixed module" do
    source = """
    defmodule MixedFeatures do
      def init(arg), do: {:ok, arg} # GenServer callback
      def index(conn, _params), do: conn # Phoenix action
      defp recursive_helper(0), do: 0
      defp recursive_helper(n), do: n + recursive_helper(n-1) # Recursive & private
      def public_one(), do: :ok # Public
    end
    """
    {:ok, ast} = Parser.parse(source)
    report = Analyzer.analyze(ast)
    
    expected_patterns = [
      :genserver_callbacks, 
      :phoenix_actions, 
      :private_functions, 
      :public_functions, 
      :recursive_functions
    ] |> Enum.sort()
    
    assert Enum.sort(report.patterns_detected) == expected_patterns
  end


  # --- Tests for detect_patterns/2 ---
  test "detect_patterns/2 correctly identifies :genserver_callbacks" do
    source = "defmodule S do def init(a), do: a; def handle_call(a,b,c), do: {a,b,c}; end"
    {:ok, ast} = Parser.parse(source)
    assert Analyzer.detect_patterns(ast, [:genserver_callbacks]) == [:genserver_callbacks]
  end

  test "detect_patterns/2 correctly identifies :phoenix_actions" do
    source = "defmodule C do def index(c,p), do: {c,p}; def show(c,p), do: {c,p}; end"
    {:ok, ast} = Parser.parse(source)
    assert Analyzer.detect_patterns(ast, [:phoenix_actions]) == [:phoenix_actions]
  end
  
  test "detect_patterns/2 correctly identifies :phoenix_live_view_callbacks" do
    source = "defmodule LV do def mount(a,b,c), do: {a,b,c}; def render(a), do: a; end"
    {:ok, ast} = Parser.parse(source)
    assert Analyzer.detect_patterns(ast, [:phoenix_live_view_callbacks]) == [:phoenix_live_view_callbacks]
  end

  test "detect_patterns/2 correctly identifies :public_functions" do
    source = "defmodule P do def a, do: 1; defp b, do: 2; end"
    {:ok, ast} = Parser.parse(source)
    assert Analyzer.detect_patterns(ast, [:public_functions]) == [:public_functions]
  end

  test "detect_patterns/2 correctly identifies :private_functions" do
    source = "defmodule P do def a, do: 1; defp b, do: 2; end"
    {:ok, ast} = Parser.parse(source)
    assert Analyzer.detect_patterns(ast, [:private_functions]) == [:private_functions]
  end

  test "detect_patterns/2 correctly identifies :recursive_functions" do
    source = "defmodule R do def f(0), do: 0; def f(n), do: f(n-1); end"
    {:ok, ast} = Parser.parse(source)
    assert Analyzer.detect_patterns(ast, [:recursive_functions]) == [:recursive_functions]
  end

  test "detect_patterns/2 handles ASTs with no matching patterns" do
    source = "defmodule NonMatching do def regular_func(a), do: a; end"
    {:ok, ast} = Parser.parse(source)
    assert Analyzer.detect_patterns(ast, [:genserver_callbacks, :recursive_functions]) == []
  end

  test "detect_patterns/2 handles multiple patterns in one AST" do
    source = """
    defmodule MultiPattern do
      def init(state), do: {:ok, state} # GenServer, Public
      defp helper(0), do: 0
      defp helper(n), do: n + helper(n-1) # Recursive, Private
    end
    """
    {:ok, ast} = Parser.parse(source)
    targets = [:genserver_callbacks, :recursive_functions, :public_functions, :private_functions]
    expected = targets |> Enum.sort() # All should be detected
    assert Analyzer.detect_patterns(ast, targets) |> Enum.sort() == expected
  end
  
  test "detect_patterns/2 returns empty list if no patterns are targeted" do
    source = "defmodule M, do: (def f, do: 1)"
    {:ok, ast} = Parser.parse(source)
    assert Analyzer.detect_patterns(ast, []) == []
  end
  
  test "detect_patterns/2 ignores unknown pattern targets" do
    source = "defmodule M, do: (def init(_), do: :ok)" # GenServer callback
    {:ok, ast} = Parser.parse(source)
    assert Analyzer.detect_patterns(ast, [:genserver_callbacks, :unknown_pattern_foo]) == [:genserver_callbacks]
  end
end
