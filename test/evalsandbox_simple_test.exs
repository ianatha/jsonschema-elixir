defmodule EvalSandboxSimpleTest do
  use ExUnit.Case

  # import EvalSandbox.SimpleEvaluator, only: [eval_quoted: 1]

  # test "simple integer" do
  #   code = Code.string_to_quoted!("5")
  #   assert eval_quoted(code) == {:value, 5, [], {:integer, 0, 5}}
  # end

  # test "simple addition" do
  #   code = Code.string_to_quoted!("2 + 3")
  #   assert eval_quoted(code) == {:value, 5, [], {{:op, 1, :+, {:integer, 0, 2}, {:integer, 0, 3}}}}
  # end

  # test "more addition" do
  #   code = Code.string_to_quoted!("x = (2 + 3) * 5")
  #   assert eval_quoted(code) == {:value, 25, [_x@1: 25], {{:op, 1, :*, {:op, 1, :+, {:integer, 0, 2}, {:integer, 0, 3}}, {:integer, 0, 5}}}}
  # end

  # test "even more addition" do
  #   code = Code.string_to_quoted!("x = 1\n4 + x")
  #   assert eval_quoted(code) == {:value, 5, [_x@1: 1], {:integer, 0, 1}}
  # end
end
