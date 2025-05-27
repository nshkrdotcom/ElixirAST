defmodule ElixirAST.Builder do
  # Added :function_instrumentation_opts
  defstruct output_format: :simple, 
            function_instrumentation_opts: nil, # Example: %{target_spec: :all, log_opts: true}
            other_config: %{}

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  # Corresponds to ElixirAST.instrument_functions/3
  def instrument_functions(config, target_spec, instrumentation_opts) do
    log_opts = Keyword.get(instrumentation_opts, :log_entry_exit, false) # Simplified
    new_instr_opts = %{target_spec: target_spec, log_opts: log_opts}
    %__MODULE__{config | function_instrumentation_opts: new_instr_opts}
  end

  # Corresponds to ElixirAST.validate/1
  def validate(config) do
    # Very basic validation for now
    if config.function_instrumentation_opts && 
       is_map(config.function_instrumentation_opts) do
      # Check if target_spec is one of the allowed atoms
      allowed_targets = [:all, :public, :private] # Add other valid complex specs later
      target_spec = config.function_instrumentation_opts.target_spec
      
      if Enum.member?(allowed_targets, target_spec) or 
         (is_tuple(target_spec) && (elem(target_spec,0) == :only || elem(target_spec,0) == :except) ) do # Basic check for tuple specs
        :ok
      else
        {:error, :invalid_function_instrumentation_target_spec}
      end
    else
      if config.function_instrumentation_opts == nil do # Default config is valid
        :ok
      else
        # This case might be redundant if the first 'if' covers all non-nil, non-map cases.
        # However, explicitly handling unexpected types for function_instrumentation_opts.
        {:error, :invalid_function_instrumentation_opts_format} 
      end
    end
  end
end
