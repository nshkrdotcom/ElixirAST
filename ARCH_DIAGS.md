# Architectural Diagrams for ElixirAST

## 1. Core Components

```mermaid
graph TB
    subgraph "Input Layer"
        SOURCE[Source Code (String)]
        AST_INPUT[Raw AST (Optional)]
        CONFIG_BUILDER[Instrumentation Config (via Builder API)]
    end
    
    subgraph "ElixirAST Core Engine"
        PARSER[Core.Parser (Source -> AST, Node ID Assignment)]
        ANALYZER[Core.Analyzer (Pattern Detection, Target Identification)]
        TRANSFORMER[Core.Transformer (AST Traversal & Modification)]
        INJECTOR[Core.Injector (Instrumentation Code Generation)]
    end
    
    subgraph "Output & Runtime Support"
        INSTRUMENTED_AST[Instrumented AST (Output of Transform)]
        CONSOLE_LOGGER[Output.Console (Runtime Logging Utilities)]
    end
    
    subgraph "API Layer (ElixirAST Module)"
        PUBLIC_API[ElixirAST Public Functions]
        BUILDER_MODULE[ElixirAST.Builder (Fluent API State)]
        PATTERN_MODULE[ElixirAST.Patterns (Pattern Definitions)]
    end
    
    %% Input flow
    SOURCE --> PARSER
    AST_INPUT --> ANALYZER
    CONFIG_BUILDER --> ANALYZER
    
    %% Core processing
    PARSER --> ANALYZER
    ANALYZER --> TRANSFORMER
    TRANSFORMER --> INJECTOR
    
    %% API integration
    PUBLIC_API --> BUILDER_MODULE
    BUILDER_MODULE --> PATTERN_MODULE
    BUILDER_MODULE --> CONFIG_BUILDER
    
    %% Output
    INJECTOR --> INSTRUMENTED_AST
    
    %% Runtime (conceptual link for instrumented code)
    INSTRUMENTED_AST -.->|Instrumented code calls| CONSOLE_LOGGER
    
    %% Styling
    classDef inputClass fill:#e1f5fe,stroke:#333,stroke-width:2px
    classDef coreClass fill:#c8e6c9,stroke:#333,stroke-width:2px
    classDef outputClass fill:#fff3e0,stroke:#333,stroke-width:2px
    classDef apiClass fill:#f3e5f5,stroke:#333,stroke-width:2px
    
    class SOURCE,AST_INPUT,CONFIG_BUILDER inputClass
    class PARSER,ANALYZER,TRANSFORMER,INJECTOR coreClass
    class INSTRUMENTED_AST,CONSOLE_LOGGER outputClass
    class PUBLIC_API,BUILDER_MODULE,PATTERN_MODULE apiClass
```

## 2. Module Structure

```mermaid
graph TD
    subgraph "lib/elixir_ast/"
        direction LR
        elixir_ast_ex["elixir_ast.ex (Main public API module)"]

        subgraph "core/"
            direction TB
            parser_ex["parser.ex (AST parsing, node ID assignment)"]
            analyzer_ex["analyzer.ex (Code pattern analysis, target identification)"]
            transformer_ex["transformer.ex (AST transformation engine, traversal)"]
            injector_ex["injector.ex (Instrumentation code generation & injection utilities)"]
        end

        subgraph "api/"
            direction TB
            builder_ex["builder.ex (Fluent API builder struct and functions)"]
            patterns_ex["patterns.ex (Predefined pattern matchers e.g., GenServer, Phoenix)"]
            config_structs_ex["config_structs.ex (Internal structs for configuration representation)"]
        end

        subgraph "output/"
            direction TB
            console_ex["console.ex (Runtime console logging functions)"]
            formatter_ex["formatter.ex (Output formatting utilities simple, detailed, JSON)"]
        end

        elixir_ast_ex --> core/
        elixir_ast_ex --> api/
        elixir_ast_ex --> output/
    end
```

## 3. MVP Feature Interactions

```mermaid
graph TD
    F1["F1: AST Parser & Node ID"]
    F2["F2: Instrumentation API (Builder)"]
    F3["F3: AST Transformation Engine"]
    F4["F4: Console Output System"]
    F5["F5: Test Harness & Examples"]

    F2 -- Configures --> F3
    F1 -- Provides AST to --> F3
    F3 -- Uses AST from/Understands via --> F1
    F3 -- Injects calls to --> F4
    F3 -- Instrumented Code calls --> F4
    
    F5 -- Uses --> F1
    F5 -- Uses --> F2
    F5 -- Uses --> F3
    F5 -- Uses --> F4

    classDef feature fill:#lightgrey,stroke:#333,stroke-width:2px;
    class F1,F2,F3,F4,F5 feature;
```
