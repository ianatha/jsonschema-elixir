defmodule JSONSchemaTest do
  use ExUnit.Case

  test "type check Box" do
    a = %TestWorld.ToDo{id: 1, done: false}
    assert :ok = TestWorld.ToDo.__type_check(a)
    assert {:error, _} = TestWorld.Order.__type_check(a)

    b = {}
    assert {:error, _} = TestWorld.ToDo.__type_check(b)
    assert {:error, _} = TestWorld.Order.__type_check(b)

    c = %TestWorld.ToDo{id: "string", done: false}
    assert [:ok, :ok, :not_an_integer] = TestWorld.ToDo.__type_check(c)
  end

  test "boxing metadata is captured correctly" do
    assert TestWorld.Company.__meta()[:rating][:title] == "Your Rating"
  end

  test "generates correct schema for TestWorld.Order" do
    assert JSONSchema.schema(TestWorld.Order) == %{
             "$id": "#",
             properties: %{
               id: %{"$id": "#/properties/id", type: :integer},
               type: %{"$id": "#/properties/type", enum: [:pos, :internet, :phone, :recurring], type: :string}
             },
             type: :object
           }
  end

  test "generates correct schema for TestWorld.User" do
    assert JSONSchema.schema(TestWorld.User) == %{
             "$id": "#",
             properties: %{
               active: %{"$id": "#/properties/active", type: :boolean},
               id: %{"$id": "#/properties/id", type: :integer},
               name: %{"$id": "#/properties/name", type: :string},
               signins: %{
                 "$id": "#/properties/signins",
                 type: :array,
                 items: %{
                   "$id": "#/properties/signins/items",
                   type: :integer
                 }
               }
             },
             type: :object
           }
  end

  test "generates correct schema for TestWorld.Account" do
    assert JSONSchema.schema(TestWorld.Account) == %{
             "$id": "#",
             properties: %{
               company: %{
                 "$id": "#/properties/company",
                 type: :object,
                 properties: %{
                   domain: %{"$id": "#/properties/company/properties/domain", type: :string},
                   id: %{"$id": "#/properties/company/properties/id", type: :integer},
                   name: %{"$id": "#/properties/company/properties/name", type: :string},
                   rating: %{
                     "$id": "#/properties/company/properties/rating",
                     type: :number,
                     examples: [5.0],
                     title: "Your Rating"
                   }
                 }
               },
               user: %{
                 "$id": "#/properties/user",
                 properties: %{
                   active: %{"$id": "#/properties/user/properties/active", type: :boolean},
                   id: %{"$id": "#/properties/user/properties/id", type: :integer},
                   name: %{"$id": "#/properties/user/properties/name", type: :string},
                   signins: %{
                     "$id": "#/properties/user/properties/signins",
                     type: :array,
                     items: %{
                       "$id": "#/properties/user/properties/signins/items",
                       type: :integer
                     }
                   }
                 },
                 type: :object
               }
             },
             type: :object
           }
  end

  test "generates correct schema for TestWorld.Company" do
    assert JSONSchema.schema(TestWorld.Company) == %{
             "$id": "#",
             properties: %{
               domain: %{"$id": "#/properties/domain", type: :string},
               id: %{"$id": "#/properties/id", type: :integer},
               name: %{"$id": "#/properties/name", type: :string},
               rating: %{
                 "$id": "#/properties/rating",
                 type: :number,
                 examples: [5.0],
                 title: "Your Rating"
               }
             },
             type: :object
           }
  end
end
