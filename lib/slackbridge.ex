defmodule Slackbridge do
  def slack_interactive(event) do
    %{"actions" => actions} = event
    selected_action = hd(actions)["value"]

    resume_task(selected_action)

    ""
  end

  @spec process_slack_event(any, any) :: :ok
  def process_slack_event(
        "event_callback",
        %{
          "event" =>
            %{
              "type" => "message",
              "channel" => _channel,
              "text" => msg,
              "ts" => ts
            } = _event
        } = _eventcb
      ) do

    if msg == "!init", do: initiate(ts)

    :ok
  end

  def process_slack_event(_eventtype, event) do
    IO.inspect(event)
    :ok
  end

  def task(code, bindings) do
    output = start_task(code, bindings)
    Agent.update(__MODULE__, fn _ -> {output, bindings} end)
  end

  def ss_ask_question(ts, recp, msg, question) do
    yes_no_question(recp, msg, question, "123", ts)
    throw(:__suspend__)
  end

  def ss_send_message(ts, recp, msg) do
    Slack.Web.Chat.post_message(recp, msg, %{as_user: true, thread_ts: ts})
    :ok
  end

  @code """
    response1 = Slackbridge.ss_ask_question(
      ts,
      "U2ZQ4HK8D",
      "I need your quick input on something1.",
      "We're about to :boom: so-and-so. Is that alright?"
    )
    response2 = Slackbridge.ss_ask_question(
      ts,
      "U2ZQ4HK8D",
      "I need your quick input on something2.",
      "We're about to :boom: so-and-so. Is that alright?"
    )
    Slackbridge.ss_send_message(ts, "U2ZQ4HK8D", "I heard you say " <> response1 <> " and then " <> response2)

    if response1 == response2 do
      Slackbridge.ss_send_message(ts, "U2ZQ4HK8D", "I appreciate your consistency")
    end
  """

  def resume_task(result) do
    {{:suspension, transcript}, bindings} = Agent.get(__MODULE__, & &1)
    t2 = EvalSandbox.Traced2Evaluator.enrich_with_result(transcript, result)
    output = EvalSandbox.Traced2Evaluator.eval(@code, bindings, t2)
    Agent.update(__MODULE__, fn _ -> {output, bindings} end)
  end

  def start_task(code, bindings) do
    EvalSandbox.Traced2Evaluator.eval(code, bindings)
  end

  def initiate(ts) do
    task(@code, [ts: ts])
  end

  def yes_no_question(recp, msg, question, cb_id, ts) do
    multiple_choice_question(
      recp,
      msg,
      question,
      [
        %{text: ":thumbsup:", type: "button", value: "yes", name: "yes"},
        %{text: ":thumbsdown:", type: "button", value: "no", name: "no"}
      ],
      cb_id,
      ts
    )
  end

  def multiple_choice_question(recp, msg, question, actions, cb_id, ts) do
    attachments =
      [
        %{
          text: question,
          callback_id: cb_id,
          actions: actions
        }
      ]
      |> Poison.encode!()

    %{"message" => %{"ts" => response_ts}} =
      Slack.Web.Chat.post_message(recp, msg, %{as_user: true, attachments: [attachments], thread_ts: ts})

    response_ts
  end

  def slack_respond_challenge(challenge) do
    %{"challenge" => challenge}
  end
end
