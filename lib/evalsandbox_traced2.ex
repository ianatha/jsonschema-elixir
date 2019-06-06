defmodule EvalSandbox.Traced2Evaluator do
  require Keyword, as: KW
  import Code, only: [string_to_quoted!: 1]

  defguard is_literal(x)
           when is_atom(x) or is_binary(x) or is_bitstring(x) or is_boolean(x) or is_number(x) or
                  is_list(x)

  defmacro defasync(name, do: block) do
    x = Macro.escape(block)
    caller = Macro.escape(__CALLER__)
    quote do
      def unquote(name) do
        IO.inspect({:async, unquote(x), unquote(caller)})
        unquote(instrument(block))
      end
    end
  end

  defp x(c) when is_literal(c), do: c
  defp x({_1, _2} = c), do: c
  defp x({_varname, _meta, nil} = c), do: c
  defp x({fnname, _meta, args} = c) when is_atom(fnname) and is_list(args) do
    if not Macro.special_form?(fnname, length(args)) do
      quote do
        IO.inspect({:call, unquote(fnname)})
        unquote(c)
      end
    else
      c
    end
  end
  defp x({{:., _fnmeta, fnpath}, _meta, args} = c) when is_list(fnpath) and is_list(args) do
        quote do: EvalSandbox.Traced2Evaluator.random_func(unquote(c))
        # Macro.special_form?(name, arity)
  end

  defp instrument(code, acc) do
    {x(code), acc}
  end

  defp instrument(code) do
    Macro.postwalk(code, 0, &instrument/2)
  end

  defp function_call(buffer), do: &function_call(buffer, &1, &2)

  defmodule MyAppError do
    defexception [:message]
  end

  defp function_call(buffer, {module, func}, args) do
    cache_result =
      buffer |> Agent.get(fn acc ->
        case Enum.at(acc |> KW.get(:transcript), acc |> KW.get(:i)) do
          {:fn, ^module, ^func, ^args, result} -> {:from_cache, result}
          nil -> {:none}
          _ -> raise ArgumentError, message: "invalid transcript - entry doesn't match call"
        end
      end)

    result =
      case cache_result do
        {:from_cache, result} ->
          buffer |> Agent.update(fn acc ->
            acc
            |> KW.update!(:i, fn i -> i + 1 end)
          end)

          result

        {:none} ->
          try do
            result = :erlang.apply(module, func, args)

            buffer |> Agent.update(fn acc ->
              acc
              |> KW.update!(:i, fn i -> i + 1 end)
              |> KW.update!(:transcript, fn t -> t ++ [{:fn, module, func, args, result}] end)
            end)

            result
          catch
            :__suspend__ ->
              buffer |> Agent.update(fn acc ->
                acc
                |> KW.update!(:transcript, fn t -> t ++ [{:fn_suspended, module, func, args}] end)
              end)

              throw(:__suspend__)

              :__suspended__
          end
      end

    result
  end

  def enrich_with_result([], _), do: []

  def enrich_with_result([h | t], res),
    do: [enrich_with_result(h, res)] ++ enrich_with_result(t, res)

  def enrich_with_result({:fn_suspended, mod, fun, args}, res), do: {:fn, mod, fun, args, res}
  def enrich_with_result({:fn, _, _, _, _} = o, _), do: o

  @doc """
  Converts an Elixir quoted expression to Erlang abstract format
  """
  def quoted_to_erl(quoted, env, scope) do
    {expanded, new_env} = quoted |> :elixir_expand.expand(env)
    {erl, new_scope} = :elixir_erl_pass.translate(expanded, scope)
    {erl, new_env, new_scope}
  end

  def eval(code_str, binding \\ [], transcript \\ []) do
    code_str |> string_to_quoted! |> _eval(binding, transcript)
  end

  def eval_quoted(quoted, binding \\ [], transcript \\ []) do
    quoted |> _eval(binding, transcript)
  end

  defp _eval(code, binding, transcript) do
    env = [] |> :elixir.env_for_eval
    scope = env |> :elixir_env.env_to_scope

    {parsed_binding, parsed_vars, parsed_scope} = :elixir_erl_var.load_binding(binding, scope)
    parsed_env = :elixir_env.with_vars(env, parsed_vars)
    {erl, _new_env, new_scope} = quoted_to_erl(code, parsed_env, parsed_scope)
    {:ok, buffer} = Agent.start_link(fn -> [i: 0, transcript: transcript] end)

    res =
      case erl do
        {:atom, _, atom} ->
          {:value, atom, binding, []}

        _ ->
          try do
            {:value, value, new_binding} =
              :erl_eval.expr(erl, parsed_binding, :none, {:value, function_call(buffer)}, :none)

            {:value, value, :elixir_erl_var.dump_binding(new_binding, new_scope),
             buffer |> Agent.get(&(&1)) |> Keyword.get(:transcript)}
          catch
            :__suspend__ ->
              {:suspension, buffer |> Agent.get(&(&1)) |> Keyword.get(:transcript)}
          end
      end

    buffer |> Agent.stop
    res
  end
end
