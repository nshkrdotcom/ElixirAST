# ElixirAST Algorithm Explanations

## AST Parsing & Node ID Assignment (`ElixirAST.Core.Parser`)

This component is foundational to ElixirAST, responsible for transforming raw Elixir source code into a structured Abstract Syntax Tree (AST) and then annotating this tree with unique, stable, and deterministic identifiers for its nodes.

### 1. AST Parsing

The ElixirAST library begins its process by converting Elixir source code, provided as a string, into an Abstract Syntax Tree (AST). This is a fundamental step in understanding and manipulating the code's structure. Elixir provides built-in capabilities for this, notably the `Code.string_to_quoted/1` function.

When `Code.string_to_quoted/1` processes a string of Elixir code, it returns a quoted expression. This quoted expression is Elixir's representation of the code's AST. In Elixir, an AST is typically a nested structure of tuples, atoms, and basic data types. For example, a function definition `def my_func(a), do: a + 10` would be represented as a tuple like `{:def, context, [{:my_func, context, [{:a, context, nil}]}, [do: {:+, context, [{:a, context, nil}, 10]}]]}`. Each element in this structure (like `:def`, `:my_func`, `:+`, `:a`, `10`) is an AST node, providing a detailed, machine-readable blueprint of the original code.

### 2. Node ID Assignment

Once the AST is obtained, ElixirAST assigns unique, stable, and deterministic identifiers (Node IDs) to relevant nodes within this tree. This is crucial for several reasons:
*   **Precise Targeting:** Node IDs allow the instrumentation engine to pinpoint exactly where to apply transformations or inject code, even in complex or nested structures.
*   **Stability:** If the source code doesn't change significantly, the IDs for existing nodes should remain the same across different compilations, allowing for consistent behavior.
*   **Determinism:** The ID generation process must always produce the same ID for the same node given the same AST, ensuring reproducibility.

The `Core.Parser` module is responsible for this, likely through a function like `assign_node_ids/1`. This function would traverse the AST (commonly using a depth-first traversal algorithm) and, for each relevant node, generate and attach an ID. "Relevant AST nodes," as per the product requirements, include modules, function definitions (`def`, `defp`, etc.), and various expressions.

The ID itself is stored in the node's metadata, typically a keyword list accessible via `elem(node_ast, 2)` for 3-element tuple AST nodes. The PRD suggests using the key `:elixir_ast_node_id`.

Several strategies can be employed for generating these Node IDs:

*   **Path-based IDs:**
    *   **Concept:** An ID is constructed by concatenating information from the node's ancestors, forming a unique "path" from the root of the AST to the node. For example, an expression within a function might get an ID like `"MyModule:my_function/1:body:expr_3"`.
    *   **Pros:** Relatively straightforward to implement and understand. Can be quite stable if the overall structure of the code is maintained.
    *   **Cons:** IDs can become unstable if code is significantly restructured (e.g., a function is renamed, or a block of code is moved into a new nested structure). This could make it harder to maintain consistent instrumentation across such changes.

*   **Content-based Hashing:**
    *   **Concept:** A hash (e.g., SHA256) is generated based on the content or a canonical representation of the AST node itself (and potentially its children or key properties).
    *   **Pros:** Highly deterministic. IDs remain stable for a node as long as its own content doesn't change, even if it's moved within the AST.
    *   **Cons:** Can be computationally more intensive. Care must be taken to define what "content" is included in the hash to avoid unintended ID changes due to minor, semantically irrelevant variations (e.g., metadata changes not related to code structure). Potential for hash collisions, though unlikely with good hashing algorithms.

*   **Sequential Numbering during Traversal:**
    *   **Concept:** As the AST is traversed, nodes are assigned IDs like `"node_1"`, `"node_2"`, etc., in the order they are visited.
    *   **Pros:** Very simple to implement.
    *   **Cons:** Highly unstable. Any reordering of code, or even adding/removing unrelated code, can change the IDs of subsequent nodes, making it unsuitable for most practical instrumentation scenarios that require stability.

A robust implementation might use a hybrid approach or prioritize path-based IDs with careful consideration for stability factors. The key is that the chosen method must reliably produce unique, stable, and deterministic IDs for effective and consistent instrumentation.

## AST Transformation Engine & Code Injection (`ElixirAST.Core.Transformer` & `ElixirAST.Core.Injector`)

After the AST has been parsed and its nodes assigned unique IDs, the "AST Transformation Engine" comes into play. This engine is the heart of ElixirAST's instrumentation capabilities. It takes the ID-annotated AST and an "Instrumentation Configuration" object to produce a new, modified AST that includes the desired instrumentation logic (e.g., logging calls, variable captures).

### 1. Overview of the Transformation Process

*   **Inputs:**
    1.  **ID-Annotated AST:** The original source code's AST, enriched with unique node identifiers by the `ElixirAST.Core.Parser`.
    2.  **Instrumentation Configuration:** An object, typically built using `ElixirAST.Builder` (as per F2), that specifies what to instrument and how. This configuration details target nodes (e.g., specific functions or modules identified by their node IDs or patterns), the type of instrumentation (e.g., entry/exit logging, variable capture), and any custom code to be injected.

*   **Goal:** The primary goal is to produce a new Elixir AST. This new AST, when compiled and executed, will run the original code's logic *plus* the additional instrumentation behaviors defined in the configuration.

*   **Semantic Preservation:** A critical requirement is that the instrumentation process must not alter the original semantics or behavior of the code being instrumented. The injected code should be "transparent" in terms of the original program's execution flow and results, aside from the intended side-effects of instrumentation (like logging).

### 2. Role of Instrumentation Configuration

The Instrumentation Configuration, defined through the fluent API of `ElixirAST.Builder`, is the blueprint for the transformation process. It dictates:

*   **Targeting:** Which parts of the code to modify. This can be based on:
    *   Specific node IDs (e.g., instrument function with ID `MyModule:my_func/1`).
    *   Patterns (e.g., all public functions in a module, all GenServer callbacks).
    *   Code structure (e.g., before every return statement in a function).
*   **Actions:** What instrumentation to apply. This includes:
    *   Logging function entry/exit points.
    *   Capturing and logging the values of specific variables or expressions.
    *   Injecting custom Elixir code snippets provided by the user.
*   **Data:** What specific information to log (e.g., function arguments, return values, timestamps, custom messages).

The `Core.Transformer` consults this configuration extensively to determine if and how each node in the AST should be modified.

### 3. AST Traversal (`Core.Transformer`)

The `ElixirAST.Core.Transformer` module is responsible for navigating the ID-annotated AST and applying the transformations.

*   **Traversal Mechanism:** A depth-first traversal (e.g., using `Macro.prewalk/2` or `Macro.postwalk/2`) is a common and effective way to visit each node in the AST.
    *   `Macro.prewalk/2`: Processes a node *before* its children. Useful if transformations on a parent node might affect how children are processed or if the context of the parent is needed to decide on transforming children.
    *   `Macro.postwalk/2`: Processes a node *after* its children have been processed. Useful if transformations on children might alter the parent node, or if the results of child transformations are needed to correctly transform the parent.
    The choice (or combination) depends on the specific transformation being applied.

*   **Decision Making:** At each node visited, the `Transformer` checks the Instrumentation Configuration:
    *   Does the current node's ID (or its properties) match any targeting rules in the configuration?
    *   Are there any child-specific rules that apply if this is a structural node (like a function definition or a block)?
    *   Based on the matching rules, it determines what action (if any) the `Core.Injector` should take for this node.

### 4. Code Injection (`Core.Injector`)

The `ElixirAST.Core.Injector` module is responsible for generating the AST snippets for the instrumentation code and then inserting them into the main AST at the locations determined by the `Transformer`.

*   **Metaprogramming Power:** Elixir's powerful metaprogramming capabilities, particularly `quote`, `unquote`, and macros, are fundamental here.
    *   `quote`: Allows the creation of Elixir AST snippets directly within Elixir code. For example, `quote do: IO.puts("Hello")` generates the AST for an `IO.puts/1` call.
    *   `unquote`: Used within a `quote` block to inject existing variables or AST fragments into the generated AST. This is crucial for parameterizing the injected code (e.g., injecting a specific node ID or a variable name to be logged).
    *   Macros: Can be defined to encapsulate complex AST generation patterns, making the injector logic cleaner and more reusable.

*   **Conceptual Examples of Injection Types:**

    *   **Function Entry/Exit Logging:**
        *   **Concept:** To log entry, code is injected at the beginning of the function body. To log exit, code is injected before every return point (including implicit returns at the end of the body and explicit `return` calls if they were supported, though Elixir relies on the last expression's value).
        *   **Implementation:**
            The function's body (which is itself an AST, often a block like `{:__block__, [], [...]}`) is modified.
            For entry logging: `quote do: ElixirAST.Output.Console.log_entry(node_id, args_map); unquote(original_body_ast) end`
            For exit logging (simplified, actual implementation needs to handle multiple return paths and capture the return value):
            A common technique is to wrap the entire function body or transform its final expression. For instance, if `original_body_ast` is the function's body:
            `quote do
               result = begin unquote(original_body_ast) end
               ElixirAST.Output.Console.log_exit(node_id, result)
               result # Ensure the original return value is preserved
             end`
        *   **Argument/Return Value Capture:** Arguments can be captured by referencing their names (available in the AST context) within the `quote`d block for entry logging. Return values are captured by assigning the result of the original body to a temporary variable and then logging that variable, as shown above.

    *   **Variable Capture:**
        *   **Concept:** Injecting code to log a variable's value at a specific point.
        *   **Implementation:** If the target is an expression where `my_var` is in scope:
            `quote do
               logged_value = unquote(Macro.var(:my_var, nil)) # AST for the variable itself
               ElixirAST.Output.Console.log_variable(node_id, "my_var", logged_value)
               unquote(Macro.var(:my_var, nil)) # Ensure the original expression value (if this replaces an expression) is preserved
             end`
            If simply inserting a logging statement without replacing an expression, the last line (preserving the original expression) might not be needed, or the injection point would be carefully chosen (e.g., *after* an assignment).

    *   **Custom Code Injection:**
        *   **Concept:** Inserting user-provided, pre-quoted Elixir code at specified locations.
        *   **Implementation:** The `Transformer` identifies the target AST node. The `Injector` then splices the user's quoted code (which is already an AST) into the main AST.
            Example: Inserting `user_code_ast` before an `expression_ast`:
            `quote do
               unquote(user_code_ast)
               unquote(expression_ast)
             end`
        *   **Variable Scope (`context_vars`):** If the custom code needs access to variables from the instrumentation context (e.g., the value of `some_var` at the injection point), the `Injector` might need to explicitly prepare these variables, perhaps by creating a binding map or by ensuring the `quote` environment correctly captures them. This can be complex and requires careful handling of Elixir's hygiene rules for macros and quoted expressions.

*   **Maintaining Semantic Integrity:** This is paramount.
    *   **Expression Values:** If an expression `original_expr` is being logged, the injected code should often be `log(original_expr)` or, more robustly, `temp = original_expr; log(temp); temp`. This ensures that if `original_expr` was, for example, the condition of an `if` statement, logging it doesn't consume its value or change the control flow.
    *   **Blocks:** When injecting into a block (e.g., `do...end`), new statements are typically added to the list of expressions within the block. The order matters.
    *   **Side Effects:** Injected code should generally avoid introducing new side effects beyond the intended instrumentation (e.g., don't modify variables that the original code relies on, unless that's the specific purpose of a custom instrumentation).

### 5. Handling Edge Cases

Transforming Elixir AST is non-trivial due to the language's flexibility. The `Transformer` and `Injector` must be designed to handle (or at least be aware of) various complexities:

*   **Guards:** Function clauses can have guards (`when ...`). Instrumentation code must not interfere with guard evaluation.
*   **Multi-clause Functions:** Instrumentation might need to be applied to each clause consistently.
*   **Macros:** Macros are expanded by the Elixir compiler *before* ElixirAST typically gets the AST (if it operates on source code string). If ElixirAST operates on already expanded AST, it will see the generated code. If it aims to instrument code *before* macro expansion, that's a much harder problem. The current scope seems to be post-expansion AST.
*   **Complex Pattern Matching:** In function heads or `case` statements, pattern matching can be intricate. Injecting code around these constructs requires careful AST manipulation to preserve the matching logic.
*   **Pipelines (`|>`):** Transforming parts of a pipeline requires careful reconstruction of the pipeline or understanding how `|>` is represented in the AST (as nested function calls).

Acknowledging these complexities is important for robust design, even if full solutions for all are iterative.

### 6. Output

The final output of the `ElixirAST.Core.Transformer` is a new, instrumented AST. This AST represents the original program's logic, augmented with the instrumentation code as specified by the configuration. This new AST can then be:

*   Converted back to an Elixir code string (e.g., using `Macro.to_string/1`) for inspection or further processing.
*   Compiled and executed by the Elixir runtime.

When this instrumented AST is run, it will execute the original program logic along with the injected logging or custom actions, providing insights into the program's behavior.

## Pattern Detection (`ElixirAST.Core.Analyzer` & `ElixirAST.Patterns`)

While precise Node ID targeting is powerful, ElixirAST also offers a higher-level abstraction for instrumentation through pattern-based targeting. This allows users to specify common Elixir idioms or framework-specific constructs (like GenServer callbacks or Phoenix controller actions) without needing to know the exact Node IDs of every function involved.

### 1. Purpose of Pattern Detection

*   **User Convenience:** Simplifies the instrumentation setup for common use cases. Instead of manually identifying and listing Node IDs for all GenServer callbacks in a module, a user can simply specify `target_pattern(:genserver_callbacks)`.
*   **Abstraction:** Enables the creation of more generalized instrumentation strategies that apply to categories of code elements.
*   **Maintainability:** If the underlying code changes (e.g., a new GenServer callback is added), pattern-based targeting can automatically include it in the instrumentation scope, whereas ID-based targeting would require manual updates.

### 2. General Approach

Pattern detection is primarily handled by the `ElixirAST.Core.Analyzer` module, specifically its `detect_patterns/2` function. This function takes the ID-annotated AST and the user-supplied instrumentation configuration (which may include pattern targets) as input.

The `Core.Analyzer` collaborates with the `ElixirAST.Patterns` module, which is expected to contain definitions or logic for recognizing various code patterns. The process generally involves:

1.  **AST Traversal:** The `Core.Analyzer` traverses the AST (or relevant parts, such as module definitions and their contents).
2.  **Pattern Matching Logic:** For each pattern specified in the configuration (e.g., `:genserver_callbacks`), the analyzer applies specific matching logic. This logic is defined within or utilized by `ElixirAST.Patterns`.
3.  **Node ID Collection:** When a pattern is successfully matched to one or more AST nodes (e.g., specific function definitions), their Node IDs are collected.

### 3. Conceptual Strategies for Identifying Specific Patterns

The `ElixirAST.Patterns` module would encapsulate the logic for how each supported pattern is identified. Here are conceptual approaches:

*   **GenServer Callbacks (`:genserver_callbacks`):**
    *   **Module-Level Check:** The analyzer first looks for a `use GenServer` statement within the module's AST. This is a strong indicator that the module implements GenServer behaviors.
    *   **Function Identification:** If `use GenServer` is found, the analyzer then scans for function definitions (`:def` nodes) whose names and arities match standard GenServer callbacks:
        *   `init/1`
        *   `handle_call/3`
        *   `handle_cast/2`
        *   `handle_info/2`
        *   `terminate/2`
        *   `code_change/3`
    *   The Node IDs of these identified functions are then collected.

*   **Phoenix Controller Actions (`:phoenix_actions`):**
    *   **Module-Level Check:** Look for `use MyAppWeb, :controller` or `use Phoenix.Controller` (or similar conventional markers) in the module AST.
    *   **Function Identification:** Identify public function definitions (see below) that are conventionally used as controller actions. These often have an arity of 2 (e.g., `conn, params`). Common action names include:
        *   `index/2`
        *   `show/2`
        *   `new/2`
        *   `create/2`
        *   `edit/2`
        *   `update/2`
        *   `delete/2`
    *   Heuristics might be needed, as not all public functions with arity 2 in a controller are necessarily actions. However, for MVP, matching common names is a good starting point.

*   **Phoenix LiveView Callbacks:** (Similar to GenServer/Controller)
    *   **Module-Level Check:** Look for `use Phoenix.LiveView` or `use MyAppWeb, :live_view`.
    *   **Function Identification:** Identify callback functions like `mount/3`, `handle_params/3`, `handle_event/3`, `render/1`.

*   **Public/Private Functions (`:public_functions`, `:private_functions`):**
    *   **AST Node Type:** This is relatively straightforward. The analyzer inspects the type of the function definition node:
        *   `{:def, ...}` corresponds to a public function (`def`).
        *   `{:defp, ...}` corresponds to a private function (`defp`).
    *   This pattern can be applied across an entire module or selectively.

*   **Recursive Functions (`:recursive_functions`):**
    *   **Function Body Analysis:** For each function definition, the analyzer needs to traverse its body AST.
    *   **Self-Call Detection:** It looks for function call nodes within the body that invoke the function itself. This means the called function name and arity match the signature of the function being analyzed.
        *   Example: In `def fac(n) do ... fac(n-1) ... end`, the call `fac(n-1)` would be identified.
    *   **Scope Consideration:** Care must be taken to ensure the call is to the *same* function (e.g., not a different function with the same name/arity imported from another module). Node IDs or module context can help here.
    *   **Mutual Recursion:** Detecting mutual recursion (e.g., function A calls B, and B calls A) is significantly more complex and typically requires building a call graph. The PRD specifies "recursive functions," which usually implies direct recursion as a starting point.

### 4. Output of Pattern Detection

The primary output of the `detect_patterns/2` function (or the pattern detection process within the `Core.Analyzer`) is a refined set of target Node IDs. If a user specified `target_pattern(:genserver_callbacks)` for `MyModule`, the analyzer would resolve this to the actual Node IDs of `MyModule.init/1`, `MyModule.handle_call/3`, etc.

This list of resolved Node IDs is then used by the `ElixirAST.Core.Transformer`. The transformer doesn't need to know *why* a particular Node ID was selected (whether directly by the user or via a pattern). It simply receives a list of Node IDs and applies the specified instrumentation actions to them.

This separation of concerns (Analyzer identifies targets based on patterns, Transformer applies modifications) makes the system more modular and extensible. New patterns can be added to `ElixirAST.Patterns` and recognized by the `Core.Analyzer` without requiring changes to the core transformation logic.
