defmodule JSONSchemaTest do
  use ExUnit.Case

  test "generates correct schema for TestWorld.User" do
    assert JSONSchema.schema(TestWorld.User) == %{
             "$id": "#",
             properties: [
               id: %{"$id": "#/properties/id", type: "integer"},
               name: %{"$id": "#/properties/name", type: "string"}
             ],
             type: "object"
           }
  end

  test "generates correct schema for TestWorld.Account" do
    assert JSONSchema.schema(TestWorld.Account) == %{
             "$id": "#",
             properties: [
               company: %{
                 "$id": "#/properties/company",
                 type: "object",
                 properties: [
                   domain: %{"$id": "#/properties/company/properties/domain", type: "string"},
                   id: %{"$id": "#/properties/company/properties/id", type: "integer"},
                   name: %{"$id": "#/properties/company/properties/name", type: "string"},
                   rating: %{"$id": "#/properties/company/properties/rating", type: "number"}
                 ]
               },
               user: %{
                 "$id": "#/properties/user",
                 properties: [
                   id: %{"$id": "#/properties/user/properties/id", type: "integer"},
                   name: %{"$id": "#/properties/user/properties/name", type: "string"}
                 ],
                 type: "object"
               }
             ],
             type: "object"
           }
  end

  test "generates correct schema for TestWorld.Company" do
    assert JSONSchema.schema(TestWorld.Company) == %{
             "$id": "#",
             properties: [
               domain: %{"$id": "#/properties/domain", type: "string"},
               id: %{"$id": "#/properties/id", type: "integer"},
               name: %{"$id": "#/properties/name", type: "string"},
               rating: %{"$id": "#/properties/rating", type: "number"}
             ],
             type: "object"
           }
  end
end
