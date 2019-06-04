defmodule EvalSandbox.SimpleEvaluator do
  def eval_quoted(cquoted) do
    env = :elixir.env_for_eval([])
    scope = :elixir_env.env_to_scope(env)
    binding = []
    linified_quoted = :elixir_quote.linify_with_context_counter(10, :line, cquoted)
    {parsed_binding, parsed_vars, _parsed_scope} = :elixir_erl_var.load_binding(binding, scope)
    parsed_env = :elixir_env.with_vars(env, parsed_vars)
    {erl, new_env, new_scope} = :elixir.quoted_to_erl(linified_quoted, parsed_env)
    # translated_erl = :erl2_eval.translate(erl)
    IO.inspect(erl)

    # IO.inspect({:eval_quoted, :orig_code, cquoted, :erl_code, erl, :translated_erl_code, translated_erl})

    case erl do
      {:atom, _, atom} -> {atom, erl, binding, new_env, new_scope}

      _ ->
        res =
              :simple_erl2_eval.expr(
                erl,
                parsed_binding,
                :none,
                :none,
                :none
              )

              res
    end
  end
end
