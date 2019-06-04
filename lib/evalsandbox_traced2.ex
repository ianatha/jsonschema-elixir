defmodule EvalSandbox.Traced2Evaluator do
  require Tap

  defguard is_literal(x)
           when is_atom(x) or is_binary(x) or is_bitstring(x) or is_boolean(x) or is_number(x) or
                  is_list(x)

  defp instrument(code, acc) do
    case code do
      code when is_literal(code) ->
        {code, acc}

      {_1, _2} = code ->
        {code, acc}

      {fnname, _meta, args} = code when is_atom(fnname) and is_list(args) ->
        {code, acc}

      {{:., _fnmeta, fnpath}, _meta, args} = code when is_list(fnpath) and is_list(args) ->
        new_code = quote do: EvalSandbox.Traced2Evaluator.random_func(unquote(code))
        {new_code, acc}
    end
  end

  def instrument(code) do
    Macro.postwalk(code, 0, &instrument/2)
  end

  def nlfh(buffer), do: &nlfh(buffer, &1, &2)

  def nlfh(_buffer, {:erlang, :monotonic_time}, [], _) do
    0
  end

  defmodule MyAppError do
    defexception [:message]
  end

  def nlfh(buffer, {module, func}, args) do
    cache_result =
      Agent.get(buffer, fn acc ->
        case Enum.at(Keyword.get(acc, :transcript), Keyword.get(acc, :i)) do
          {:fn, ^module, ^func, ^args, result} -> {:from_cache, result}
          nil -> {:none}
          _ -> raise ArgumentError, message: "invalid transcript - entry doesn't match call"
        end
      end)

    result =
      case cache_result do
        {:from_cache, result} ->
          Agent.update(buffer, fn acc ->
            acc
            |> Keyword.update!(:i, fn i -> i + 1 end)
          end)

          result

        {:none} ->
          result = :erlang.apply(module, func, args)

          Agent.update(buffer, fn acc ->
            acc
            |> Keyword.update!(:i, fn i -> i + 1 end)
            |> Keyword.update!(:transcript, fn t -> t ++ [{:fn, module, func, args, result}] end)
          end)

          result
      end

    result
  end

  def eval_quoted(cquoted, transcript \\ []) do
    env = :elixir.env_for_eval([])
    scope = :elixir_env.env_to_scope(env)
    binding = []
    linified_quoted = :elixir_quote.linify_with_context_counter(10, :line, cquoted)
    {parsed_binding, parsed_vars, _parsed_scope} = :elixir_erl_var.load_binding(binding, scope)
    parsed_env = :elixir_env.with_vars(env, parsed_vars)
    {erl, _new_env, new_scope} = :elixir.quoted_to_erl(linified_quoted, parsed_env)
    {:ok, buffer} = Agent.start_link(fn -> [i: 0, transcript: transcript] end)

    case erl do
      {:atom, _, atom} ->
        {:value, atom, binding, []}

      _ ->
        try do
          {:value, value, new_binding} =
            :erl_eval.expr(erl, parsed_binding, :none, {:value, nlfh(buffer)}, :none)

          {:value, value, :elixir_erl_var.dump_binding(new_binding, new_scope),
           Keyword.get(Agent.get(buffer, fn data -> data end), :transcript)}
        catch
          :__suspend__ ->
            {:suspension, Keyword.get(Agent.get(buffer, fn data -> data end), :transcript)}
        end
    end
  end
end
