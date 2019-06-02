defmodule EvalSandboxTraced2Test do
  use ExUnit.Case

  require EvalSandbox.Traced2Evaluator
  # eval_forms(Tree, Binding, Env, Scope) ->
  #   {ParsedBinding, ParsedVars, ParsedScope} = elixir_erl_var:load_binding(Binding, Scope),
  #   ParsedEnv = elixir_env:with_vars(Env, ParsedVars),
  #   {Erl, NewEnv, NewScope} = quoted_to_erl(Tree, ParsedEnv, ParsedScope),

  #   case Erl of
  #     {atom, _, Atom} ->
  #       {Atom, Binding, NewEnv, NewScope};
  #     _  ->
  #       % Below must be all one line for locations to be the same
  #       % when the stacktrace is extended to the full stacktrace.
  #       {value, Value, NewBinding} =
  #         try erl_eval:expr(Erl, ParsedBinding, none, none, none) catch ?WITH_STACKTRACE(Class, Exception, Stacktrace) erlang:raise(Class, Exception, get_stacktrace(Stacktrace)) end,
  #       {Value, elixir_erl_var:dump_binding(NewBinding, NewScope), NewEnv, NewScope}
  #   end.

  def nlfh(buffer), do: &nlfh(buffer, &1, &2, &3)

  def nlfh(_buffer, {:erlang, :monotonic_time}, [], _) do
    0
  end

  defmodule MyAppError do
    defexception [:message]
  end

  def nlfh(buffer, {module, func}, args, line) do
    Agent.update(buffer, fn acc -> acc + 1 end)
    acc = Agent.get(buffer, fn acc -> acc end)
    IO.inspect({:nlfh_start, line, acc, module, func, args})
    result = :erlang.apply(module, func, args)
    IO.inspect({:nlfh_end, line, acc, module, func, args, result})
    Agent.update(buffer, fn acc -> acc - 1 end)
    case {module, func, args} do
      {EvalSandboxTraced2Test, :testfn2, []} -> throw {:suspend, 777}
      _ -> result
    end
  end

  def rlfh({module, func}, args) do
    raise :error
  end

  defp annotate_node({op, meta, args} = node, acc), do: {{op, Keyword.put(meta, :line, acc), args}, acc + 1}
  defp annotate_node(node, acc), do: {node, acc}

  defp update_meta(q) do
    Macro.prewalk(q, 0, &annotate_node/2)
  end

  def eval_quoted(cquoted2) do
    beta = true

    cquoted = update_meta(cquoted2)
    env = :elixir.env_for_eval([])
    scope = :elixir_env.env_to_scope(env)
    binding = []
    # IO.inspect(cquoted)
    linified_quoted = :elixir_quote.linify_with_context_counter(10, :line, cquoted)
    {parsed_binding, parsed_vars, _parsed_scope} = :elixir_erl_var.load_binding(binding, scope)
    parsed_env = :elixir_env.with_vars(env, parsed_vars)
    {erl, new_env, new_scope} = :elixir.quoted_to_erl(linified_quoted, parsed_env)
    # eval_forms(elixir_quote:linify(Line, line, Tree), Binding, E).
    {:ok, buffer} = Agent.start_link fn -> 0 end

    # IO.inspect(erl)
    case erl do
      {:atom, _, atom} ->
        {atom, binding, new_env, new_scope}
      _ ->
        {:value, value, new_binding} = case beta do
          true -> try do
            :erl2_eval.expr(erl, parsed_binding, {:value, &rlfh/2}, {:value, nlfh(buffer)}, :none)
        catch
          {s, xval} -> IO.inspect({s, xval})
          {:value, "suspended", binding}
      end
          false -> :erl_eval.expr(erl, parsed_binding, {:value, &rlfh/2}, :none, :none)
        end
        {value, :elixir_erl_var.dump_binding(new_binding, new_scope), new_env, new_scope}
          #try

        # catch ?WITH_STACKTRACE(Class, Exception, Stacktrace) erlang:raise(Class, Exception, get_stacktrace(Stacktrace)) end,

    end
    #:erl_eval.expr(arg1, arg2)
    # IO.inspect(eval_env)
    # {value, binding, env, scope} = :elixir.eval_quoted(quoted,[], eval_env)
    #eval_forms(:elixir_quote.linify(Line, line, Tree), Binding, E).
    #IO.inspect(env)
    #IO.inspect(scope)
    # {value, binding}
    #{0, []}
  end

  def testfn do
    String.reverse("hi")
  end

  def testfn2 do
    :suspend
  end

  test "trace" do
    # defmodule Test123 do
    #   def a do
    #     IO.puts(:erlang.monotonic_time())
    #   end
    # end
    # s = String.split(String.reverse(String.reverse("abc") <> "abc"), "a")
    # for n <- [1, 2, 3, 4], do: n * n
  #

  code = Code.string_to_quoted!("""
      bot_name = "Ian"
      IO.puts("Our names in reverse are \#{String.reverse(bot_name)} and \#{String.reverse(EvalSandboxTraced2Test.testfn2())}")
    """)
    # Enum.map(["abc", "ian"], &String.reverse/1)
    # IO.puts(:erlang.monotonic_time())
    #
    # Test123.a()
    #IO.inspect(code)
    #{_macro_code, acc} = EvalSandbox.Traced2Evaluator.instrument(code)
    #IO.puts("\n")
    #macro_code |> Macro.expand(__ENV__) |> Macro.to_string |> IO.puts
    #IO.inspect
    IO.inspect(eval_quoted(code))
  end
end
