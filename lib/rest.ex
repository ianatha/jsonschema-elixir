defmodule RestPlug do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Poison)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  post "/" do
    {status, body} =
      case conn.body_params do
        %{"challenge" => challenge} ->
          {200, Slackbridge.slack_respond_challenge(challenge)}

        %{"event" => _event, "type" => eventtype} = data ->
          {200, Slackbridge.process_slack_event(eventtype, data)}

        _ ->
          IO.inspect(conn.body_params)
          {422, %{:error => true}}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, body |> Poison.encode!())
  end

  post "/interactive" do
    {status, body} =
      case conn.body_params do
        %{"payload" => payload} ->
          {200, payload |> Poison.decode!() |> Slackbridge.slack_interactive}

        _ ->
          {422, %{:error => true}}
      end

    conn
    |> send_resp(status, body)
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
