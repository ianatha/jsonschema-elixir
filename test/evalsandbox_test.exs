defmodule EvalSandboxTest do
  use ExUnit.Case

  require TestEvalSandbox
  require EvalSandbox.RestrictedEvaluator

  test "allowed works" do
    allowed = """
      s = String.reverse("abc")
      if s == "cba" do
        a = 123
        IO.puts(a)
      end
      s
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

  test "disallowed call in interpolated string" do
    assert_raise CompileError, fn ->
      disallowed = """
        s = "Hello \#{System.monotonic_time()}"
      """
      EvalSandbox.RestrictedEvaluator.evaluate_restricted(disallowed, TestEvalSandbox)
    end
  end
end
