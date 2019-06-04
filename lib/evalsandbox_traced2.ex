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
    result = :erlang.apply(module, func, args)
    Agent.update(buffer, fn acc -> acc ++ [{:fn, module, func, args, result}] end)
    result
  end

  def eval_quoted(cquoted) do
    env = :elixir.env_for_eval([])
    scope = :elixir_env.env_to_scope(env)
    binding = []
    linified_quoted = :elixir_quote.linify_with_context_counter(10, :line, cquoted)
    {parsed_binding, parsed_vars, _parsed_scope} = :elixir_erl_var.load_binding(binding, scope)
    parsed_env = :elixir_env.with_vars(env, parsed_vars)
    {erl, _new_env, new_scope} = :elixir.quoted_to_erl(linified_quoted, parsed_env)
    {:ok, buffer} = Agent.start_link(fn -> [] end)
    case erl do
      {:atom, _, atom} ->
        {atom, binding, []}

      _ ->
        {:value, value, new_binding} =
              :erl_eval.expr(
                erl,
                parsed_binding,
                :none,
                {:value, nlfh(buffer)},
                :none
              )

              {value, :elixir_erl_var.dump_binding(new_binding, new_scope), Agent.get(buffer, fn data -> data end)}
    end
  end
end
