defmodule ElixirAST.Api.Builder do
  @moduledoc """
  Internal. Fluent API builder for ElixirAST instrumentation configuration.
  This module holds the state of the configuration being built and
  provides helper functions to modify this state.
  """

  alias ElixirAST.ast_node # For type specs if needed for opts values

  # As per PRD_v3.md (defmodule ElixirAST.Builder section)
  defstruct [
    # Function targeting
    function_target_spec: {:instrument, :all}, # {:instrument | :skip, :all | :public | :private | {:only, list} | {:except, list}}
    pattern_targets: [], # list of pattern atoms like :genserver_callbacks

    # Instrumentation actions
    log_function_entry_exit_opts: nil, # log_entry_exit_opts() | nil

    variables_to_capture: %{}, # %{capture_point_atom => [vars_to_capture_list_or_all_atom]}
                               # capture_point_atom e.g. :entry, :before_return, {:line, num}

    expressions_to_track: [], # list of {quoted_expression, track_expressions_opts()}

    custom_injections: %{}, # %{injection_point_atom => [{quoted_code, injection_opts()}]}
                            # injection_point_atom e.g. :at_line_N, :before_return, :on_error

    # Output configuration
    output_target: :console,
    output_format: :simple, # :simple | :detailed | :json
    verbose_mode: false
  ]

  @type t :: %__MODULE__{}
  @type log_entry_exit_opts() :: [
    capture_args: boolean(),
    capture_return: boolean(),
    log_duration: boolean()
  ]
  @type capture_variables_opts() :: [at: :entry | :before_return | :on_error | {:line, pos_integer()}]
  @type track_expressions_opts() :: [log_intermediate: boolean()]
  @type injection_opts() :: [context_vars: [atom()]]


  @doc """
  Creates a new instrumentation configuration builder.
  Applies initial options like :output_target and :output_format.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      output_target: Keyword.get(opts, :output_target, :console),
      output_format: Keyword.get(opts, :output_format, :simple),
      verbose_mode: Keyword.get(opts, :verbose_mode, false)
    }
  end

  # --- Private Helper Function Implementations ---

  @spec do_instrument_functions(t(), atom() | tuple(), keyword()) :: t()
  defp do_instrument_functions(config, target_spec, instrumentation_opts) do
    log_opts = Keyword.get(instrumentation_opts, :log_entry_exit)
    capture_vars_config = Keyword.get(instrumentation_opts, :capture_variables)

    new_config = %{config |
      function_target_spec: target_spec,
      # Update log_function_entry_exit_opts only if explicitly provided
      log_function_entry_exit_opts: if(log_opts, do: log_opts, else: config.log_function_entry_exit_opts)
    }

    # Handle :capture_variables if provided
    if capture_vars_config do
      # Determine if it's a list of variables or :all, or a keyword list of options
      case capture_vars_config do
        vars when is_list(vars) or vars == :all ->
          # Default capture point is :before_return if only variables are listed
          do_capture_variables(new_config, vars, at: :before_return)
        opts when is_list(opts) ->
          # This case assumes capture_vars_config is like `[at: :entry, vars: [:a, :b]]` (not PRD standard)
          # PRD implies `capture_variables: [:state]` or `capture_variables: [at: :entry]` (latter handled by capture_variables/3)
          # For simplicity, let's assume if it's a keyword list, it's the full opts for a direct call.
          # This part of instrument_functions/3 might need clarification if capture_variables: [at: :foo] is intended.
          # The PRD for instrument_functions says: `capture_variables: [atom()] | :all | capture_variables_opts()`
          # This is ambiguous. Let's assume if it's a keyword list, it's the opts for do_capture_variables.
          # However, `capture_variables/3` is the primary way to specify detailed opts.
          # So, `instrument_functions` shortcut for `capture_variables` is likely just for `[vars]` or `:all`.
          # For now, this part remains tricky. The PRD for instrument_functions is:
          # capture_variables: [atom()] | :all | capture_variables_opts()
          # This implies the *value* of the keyword can be opts.
          # Let's stick to the simple case: if it's a list of atoms or :all, use default opts.
          # If it's a keyword list, it implies it's the full `opts` for `do_capture_variables` and `variables` part is missing.
          # This seems like a potential PRD ambiguity or needs a specific interpretation.
          # For now, if it's a keyword list, we assume it's for the main `capture_variables` function.
          # The current `do_instrument_functions` signature has `instrumentation_opts` which *contains* `capture_variables: value`.
          # Let's assume `instrumentation_opts: [capture_variables: [:a, :b]]` or `instrumentation_opts: [capture_variables: :all]`
          # If `instrumentation_opts: [capture_variables: [at: :entry]]` - this is not directly supported by this interpretation.
          # Re-evaluating: The type `[atom()] | :all | capture_variables_opts()` means the VALUE of `capture_variables` can be those.
          # So `capture_variables: [at: :entry]` is valid.
          # In this case, `variables` would be implicitly :all or need to be specified within the opts. This is not clear.
          # Given the separate `capture_variables/3` function, it's safer to assume the shortcut in
          # `instrument_functions` is for the simple cases: `[:var1, :var2]` or `:all`.
          # If `capture_variables_opts` is passed, it should likely be to `capture_variables/3`.
          # The example `instrument_functions({:only, [:handle_call]}, capture_variables: [:state])` suggests simple list.

          # Let's simplify: `instrument_functions` only handles `capture_variables: list_of_atoms_or_all`.
          # More complex cases should use `ElixirAST.capture_variables/3` directly.
          # This means `capture_variables_opts()` as a direct value for `capture_variables:` in `instrument_functions` is not handled here.
          new_config # Or raise an error for complex `capture_vars_config` type here.
        _ -> # Not a list, not :all, not a keyword list.
          new_config # Or raise error.
      end
    else
      new_config
    end
  end


  @spec do_capture_variables(t(), [atom()] | :all, capture_variables_opts()) :: t()
  defp do_capture_variables(config, variables, opts) do
    capture_point = Keyword.get(opts, :at, :before_return) # Default capture point
    vars_to_add = List.wrap(variables) # Ensure it's a list, even if :all

    new_vars_for_point = Map.get(config.variables_to_capture, capture_point, []) ++ vars_to_add
    |> Enum.uniq() # Avoid duplicates if called multiple times for same point/var

    %{config | variables_to_capture: Map.put(config.variables_to_capture, capture_point, new_vars_for_point)}
  end

  @spec do_track_expressions(t(), [ast_node()], track_expressions_opts()) :: t()
  defp do_track_expressions(config, expressions, opts) when is_list(expressions) do
    # Each call to track_expressions adds a new set of expressions with their specific options.
    # The PRD seems to imply `expressions` is `[ast_node()]`, so a list of quoted expressions.
    # And `opts` applies to all of them in that call.
    new_entries = Enum.map(expressions, fn expr -> {expr, opts} end)
    %{config | expressions_to_track: config.expressions_to_track ++ new_entries}
  end

  @spec do_inject_at_line(t(), pos_integer(), ast_node(), injection_opts()) :: t()
  defp do_inject_at_line(config, line_number, code, opts) do
    injection_point = {:at_line, line_number}
    new_injection = {code, opts} # {quoted_code, injection_opts}
    updated_injections = Map.update(config.custom_injections, injection_point, [new_injection], fn existing_list -> [new_injection | existing_list] end)
    %{config | custom_injections: updated_injections}
  end

  @spec do_inject_before_return(t(), ast_node(), injection_opts()) :: t()
  defp do_inject_before_return(config, code, opts) do
    injection_point = :before_return
    new_injection = {code, opts}
    updated_injections = Map.update(config.custom_injections, injection_point, [new_injection], fn existing_list -> [new_injection | existing_list] end)
    %{config | custom_injections: updated_injections}
  end

  @spec do_inject_on_error(t(), ast_node(), injection_opts()) :: t()
  defp do_inject_on_error(config, code, opts) do
    injection_point = :on_error
    new_injection = {code, opts}
    updated_injections = Map.update(config.custom_injections, injection_point, [new_injection], fn existing_list -> [new_injection | existing_list] end)
    %{config | custom_injections: updated_injections}
  end

  @spec do_target_pattern(t(), atom()) :: t()
  defp do_target_pattern(config, pattern_name) when is_atom(pattern_name) do
    # Appends if not already present
    %{config | pattern_targets: List.keystore(config.pattern_targets, pattern_name, 0, pattern_name) |> Keyword.values() |> Enum.uniq()}
    # A simpler way to ensure uniqueness:
    # %{config | pattern_targets: [pattern_name | config.pattern_targets] |> Enum.uniq()}
  end

  @spec do_output_to(t(), :console) :: t()
  defp do_output_to(config, target) do
    if target == :console do
      %{config | output_target: target}
    else
      # For now, silently ignore invalid target, or one could raise/add to validation error
      config
    end
  end

  @spec do_format(t(), :simple | :detailed | :json) :: t()
  defp do_format(config, format_type) do
    if Enum.member?([:simple, :detailed, :json], format_type) do
      %{config | output_format: format_type}
    else
      # Silently ignore invalid format, or one could raise/add to validation error
      config
    end
  end

  @doc """
  Validates the provided instrumentation configuration.
  Returns `:ok` if the configuration is valid, or `{:error, reasons}` otherwise.
  """
  @spec validate(config :: t()) :: :ok | {:error, [term()]}
  def validate(config) do
    errors = []

    # Validate output_target
    errors =
      if config.output_target != :console do
        [{:invalid_output_target, config.output_target} | errors]
      else
        errors
      end

    # Validate output_format
    errors =
      unless Enum.member?([:simple, :detailed, :json], config.output_format) do
        [{:invalid_output_format, config.output_format} | errors]
      else
        errors
      end

    # Validate function_target_spec
    errors =
      case config.function_target_spec do
        {:instrument, spec_val} -> validate_target_spec_val(spec_val, errors)
        {:skip, spec_val} -> validate_target_spec_val(spec_val, errors)
        _ -> [{:invalid_function_target_spec_type, config.function_target_spec} | errors]
      end

    # Validate variables_to_capture
    errors =
      Enum.reduce(config.variables_to_capture, errors, fn {point, vars_list}, acc_errors ->
        valid_point =
          case point do
            :entry -> true
            :before_return -> true
            :on_error -> true
            {:line, num} when is_integer(num) and num > 0 -> true
            _ -> false
          end

        acc_errors_after_point =
          if valid_point do
            acc_errors
          else
            [{:invalid_capture_point, point} | acc_errors]
          end

        valid_vars =
          case vars_list do
            # vars_list is already processed to be a list by do_capture_variables, even for :all
            # So it should be a list of atoms, where one of the atoms could be :all.
            # Or, if :all was passed, it becomes `[:all]`.
            list when is_list(list) ->
              Enum.all?(list, &is_atom/1)
            _ ->
              false # Should always be a list here due to `do_capture_variables`
          end

        if valid_vars do
          acc_errors_after_point
        else
          [{:invalid_variables_for_capture, {point, vars_list}} | acc_errors_after_point]
        end
      end)

    # Validate custom_injections
    errors =
      Enum.reduce(config.custom_injections, errors, fn {point, injections_list}, acc_errors ->
        valid_point =
          case point do
            :before_return -> true
            :on_error -> true
            {:at_line, num} when is_integer(num) and num > 0 -> true
            _ -> false
          end

        acc_errors_after_point =
          if valid_point do
            acc_errors
          else
            [{:invalid_injection_point, point} | acc_errors]
          end

        # Each injection is {quoted_code, injection_opts()}
        valid_injections_list =
          is_list(injections_list) &&
            Enum.all?(injections_list, fn
              {_quoted, opts} when is_list(opts) ->
                # Basic check for opts structure, e.g., context_vars is a list of atoms
                case Keyword.get(opts, :context_vars, []) do
                  vars when is_list(vars) and Enum.all?(vars, &is_atom/1) -> true
                  _ -> false # context_vars is not a list of atoms
                end
              _ -> false # Not a {quoted, opts} tuple
            end)

        if valid_injections_list do
          acc_errors_after_point
        else
          [{:invalid_custom_injection_format, {point, injections_list}} | acc_errors_after_point]
        end
      end)

    # Validate pattern_targets
    known_patterns = [
      :genserver_callbacks, :phoenix_actions, :phoenix_live_view_callbacks,
      :public_functions, :private_functions, :recursive_functions
    ]
    errors =
      Enum.reduce(config.pattern_targets, errors, fn pattern, acc_errors ->
        if Enum.member?(known_patterns, pattern) do
          acc_errors
        else
          [{:unknown_pattern_target, pattern} | acc_errors]
        end
      end)
      
    # Validate log_function_entry_exit_opts
    errors = 
      case config.log_function_entry_exit_opts do
        nil -> errors # Allowed to be nil
        opts when is_list(opts) ->
          valid_keys = [:capture_args, :capture_return, :log_duration]
          Enum.reduce(opts, errors, fn {key, val}, acc_errors ->
            cond do
              !Enum.member?(valid_keys, key) -> [{:invalid_log_entry_exit_opt_key, key} | acc_errors]
              !is_boolean(val) -> [{:invalid_log_entry_exit_opt_value, {key, val}} | acc_errors]
              true -> acc_errors
            end
          end)
        _ -> [{:invalid_log_entry_exit_opts_type, config.log_function_entry_exit_opts} | errors]
      end

    # Validate expressions_to_track (list of {quoted_expression, track_expressions_opts()})
    errors =
      Enum.reduce(config.expressions_to_track, errors, fn entry, acc_errors ->
        case entry do
          {_quoted_expr, opts} when is_list(opts) ->
            # Check opts for track_expressions_opts: [log_intermediate: boolean()]
            log_intermediate = Keyword.get(opts, :log_intermediate, false) # Default if not present
            if is_boolean(log_intermediate) do
              acc_errors
            else
              [{:invalid_track_expression_opt_value, {:log_intermediate, log_intermediate}} | acc_errors]
            end
          _ -> [{:invalid_expression_tracking_entry, entry} | acc_errors] # Entry is not {expr, opts}
        end
      end)


    if Enum.empty?(errors) do
      :ok
    else
      {:error, Enum.reverse(errors)}
    end
  end

  # --- Private validation helpers ---
  defp validate_target_spec_val({:only, list}, errors) do
    if is_list(list) && Enum.all?(list, &valid_function_spec_item?/1) do
      errors
    else
      [{:invalid_function_target_spec_list, {:only, list}} | errors]
    end
  end
  defp validate_target_spec_val({:except, list}, errors) do
    if is_list(list) && Enum.all?(list, &valid_function_spec_item?/1) do
      errors
    else
      [{:invalid_function_target_spec_list, {:except, list}} | errors]
    end
  end
  defp validate_target_spec_val(spec_atom, errors) when spec_atom in [:all, :public, :private] do
    errors
  end
  defp validate_target_spec_val(other_spec, errors) do
    [{:invalid_function_target_spec_value, other_spec} | errors]
  end

  defp valid_function_spec_item?(item) do
    is_atom(item) or
      (is_tuple(item) and tuple_size(item) == 2 and is_atom(elem(item, 0)) and is_integer(elem(item, 1)) and elem(item, 1) >= 0)
  end
end
