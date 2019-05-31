defmodule TestWorld do
  use Box

  defbox(User,
    id: integer,
    name: String.t(),
    signins: list(integer()),
    active: boolean
  )

  defbox(Company,
    id: integer,
    name: String.t(),
    domain: String.t(),
    rating: float,
    __examples: [5.0],
    __title: "Your Rating"
  )

  defbox(Account,
    user: User.t(),
    company: Company.t()
  )

  @type order_type :: :pos | :internet | :phone | :recurring

  defbox(Order,
    id: integer,
    type: TestWorld.order_type()
  )

  defbox(ToDo,
    id: integer,
    done: boolean
  )
end

defmodule TestEvalSandbox do
  use EvalSandbox

  allow(String, reverse: 1)
  allow(IO, puts: 1)
end
