defmodule EvalSandboxTraced2Test do
  use ExUnit.Case

  import Code, only: [string_to_quoted!: 1]
  import EvalSandbox.Traced2Evaluator, only: [eval_quoted: 1]

  test "simple addition" do
    {value, bindings, _transcript} = eval_quoted(string_to_quoted!("2+3"))
    assert value == 5
    assert bindings == []
  end

  test "simple addition with variables" do
    {value, bindings, transcript} = eval_quoted(string_to_quoted!("x = 2\na = x + 3"))

    assert value == 5
    assert bindings == [a: 5, x: 2]
    assert transcript == [ {:fn, :erlang, :+, [2, 3], 5} ]
  end

  test "string reversion and concatenation" do
    {value, bindings, transcript} = eval_quoted(string_to_quoted!("String.reverse(\"hello\") <> \" world\""))

    assert value == "olleh world"
    assert bindings == []
    assert transcript == [ {:fn, String, :reverse, ["hello"], "olleh"} ]
  end

  test "branching logic" do
    code = """
      if 2 + 3 > 2 do
        String.reverse("orez")
      else
        String.reverse("number")
      end
    """
    {value, bindings, transcript} = eval_quoted(string_to_quoted!(code))

    assert value == "zero"
    assert bindings == []
    assert transcript == [{:fn, :erlang, :+, [2, 3], 5}, {:fn, :erlang, :>, [5, 2], true}, {:fn, String, :reverse, ["orez"], "zero"}]
  end
end
