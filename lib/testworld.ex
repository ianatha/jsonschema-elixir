defmodule TestWorld do
  use Box

  defbox(User,
    id: integer,
    name: String.t(),
    signins: list(integer()),
    active: boolean
  )

  defbox(Company,
    id: integer, __example: 1,
    name: String.t(), __example: "Acme",
    domain: String.t(), __example: "acme.com",
    rating: float, __example: 5.0, __title: "Your Rating"
  )

  defbox(Account,
    user: User.t(),
    company: Company.t()
  )
end
