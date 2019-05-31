defmodule EvalSandboxTest do
  use ExUnit.Case

  require TestEvalSandbox
  require EvalSandbox.RestrictedEvaluator

  test "allowed works" do
    allowed = """
      s = String.reverse("abc")
    """
    assert(EvalSandbox.RestrictedEvaluator.evaluate_restricted(allowed, TestEvalSandbox) == "cba")
  end

  test "disallowed raises exception" do
    assert_raise UndefinedFunctionError, fn ->
      disallowed = """
        s = String.split("a bc", " ")
      """
      EvalSandbox.RestrictedEvaluator.evaluate_restricted(disallowed, TestEvalSandbox)
    end
  end

  test "disallowed erlang-style exception" do
    assert_raise CompileError, fn ->
      disallowed = """
        s = :string.split("a bc", " ")
      """
      EvalSandbox.RestrictedEvaluator.evaluate_restricted(disallowed, TestEvalSandbox)
    end
  end
end
