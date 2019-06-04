defmodule EvalSandboxTraced2Test do
  use ExUnit.Case

  import Code, only: [string_to_quoted!: 1]

  import EvalSandbox.Traced2Evaluator,
    only: [enrich_with_result: 2, eval_quoted: 1, eval_quoted: 2, eval_quoted: 3]

  test "simple addition" do
    {:value, value, bindings, _transcript} = eval_quoted(string_to_quoted!("2+3"))
    assert value == 5
    assert bindings == []
  end

  test "binding deref" do
    {:value, value, bindings, transcript} = eval_quoted(string_to_quoted!("x"), x: 5)

    assert value == 5
    assert bindings == [x: 5]
    assert transcript == []
  end

  test "simple addition with variables" do
    {:value, value, bindings, transcript} =
      eval_quoted(string_to_quoted!("x = 2\na = x + 3 + b"), b: 0)

    assert value == 5
    assert bindings == [a: 5, b: 0, x: 2]
    assert transcript == [{:fn, :erlang, :+, [2, 3], 5}, {:fn, :erlang, :+, [5, 0], 5}]
  end

  test "string reversion and concatenation" do
    {:value, value, bindings, transcript} =
      eval_quoted(string_to_quoted!("String.reverse(\"hello\") <> \" world\""))

    assert value == "olleh world"
    assert bindings == []
    assert transcript == [{:fn, String, :reverse, ["hello"], "olleh"}]
  end

  test "branching logic" do
    code = """
      if 2 + 3 > 2 do
        String.reverse("orez")
      else
        String.reverse("number")
      end
    """

    {:value, value, bindings, transcript} = eval_quoted(string_to_quoted!(code))

    assert value == "zero"
    assert bindings == []

    assert transcript == [
             {:fn, :erlang, :+, [2, 3], 5},
             {:fn, :erlang, :>, [5, 2], true},
             {:fn, String, :reverse, ["orez"], "zero"}
           ]
  end

  def suspending_function() do
    throw(:__suspend__)
  end

  test "suspension signaled" do
    code = """
      x = 2 + 3
      EvalSandboxTraced2Test.suspending_function()
    """

    {:suspension,
     [
       {:fn, :erlang, :+, [2, 3], 5},
       {:fn_suspended, EvalSandboxTraced2Test, :suspending_function, []}
     ]} = eval_quoted(string_to_quoted!(code))
  end

  test "result cache used" do
    {:value, value, bindings, transcript} =
      eval_quoted(string_to_quoted!("2+3"), [], [{:fn, :erlang, :+, [2, 3], 10}])

    assert value == 10
    assert bindings == []
    assert transcript == [{:fn, :erlang, :+, [2, 3], 10}]
  end

  test "resurrecting suspended task" do
    code = """
      x = 2 + 3
      y = EvalSandboxTraced2Test.suspending_function()
      x + y
    """

    {:suspension, transcript1} = eval_quoted(string_to_quoted!(code), [])

    assert transcript1 == [
             {:fn, :erlang, :+, [2, 3], 5},
             {:fn_suspended, EvalSandboxTraced2Test, :suspending_function, []}
           ]

    enriched_task_status = enrich_with_result(transcript1, 55)

    assert enriched_task_status == [
             {:fn, :erlang, :+, [2, 3], 5},
             {:fn, EvalSandboxTraced2Test, :suspending_function, [], 55}
           ]

    {:value, value, bindings, transcript2} =
      eval_quoted(string_to_quoted!(code), [], enriched_task_status)

    assert value == 60

    assert bindings == [
      x: 5,
      y: 55
    ]

    assert transcript2 == [
             {:fn, :erlang, :+, [2, 3], 5},
             {:fn, EvalSandboxTraced2Test, :suspending_function, [], 55},
             {:fn, :erlang, :+, [5, 55], 60}
           ]
  end
end
