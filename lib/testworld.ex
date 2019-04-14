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
    rating: float, __examples: [5.0], __title: "Your Rating"
  )

  defbox(Account,
    user: User.t(),
    company: Company.t()
  )
end
