defmodule EctoFiltering.QueryTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Ecto.Query

  alias EctoFiltering.Parser
  alias EctoFiltering.Query

  defmodule Car do
    use Ecto.Schema

    @primary_key {:id, :binary_id, []}
    schema "cars" do
      field :name, :string
      field :age, :integer
      has_one :brand, Brand
    end
  end

  defmodule Brand do
    use Ecto.Schema

    @primary_key {:id, :binary_id, []}
    schema "brands" do
      field :name, :string
      field :value, :integer
      belongs_to :group, Group
    end
  end

  defmodule Group do
    use Ecto.Schema

    @primary_key {:id, :binary_id, []}
    schema "brands" do
      field :name, :string
      field :value, :integer
    end
  end

  defp query(queryable \\ from(Car), filter) do
    {:ok, [ast], "", _, _, _} = Parser.bexpr(filter)
    Query.apply(queryable, ast) |> inspect()
  end

  describe "comparison filters" do
    test "equality" do
      assert query(~S|age == 42|) == inspect(from Car, where: [age: ^42])
      assert query(~S|name == "a"|) == inspect(from Car, where: [name: ^"a"])
      assert query(~S|name == true|) == inspect(from Car, where: [name: ^true])
      assert query(~S|null == null|) == inspect(from(Car))
      assert query(~S|42 == 42|) == inspect(from(Car))
      assert query(~S|name == null|) == inspect(from c in Car, where: is_nil(c.name))
      assert query(~S|null == name|) == inspect(from c in Car, where: is_nil(c.name))
    end

    test "inequality" do
      assert query(~S|age != 42|) == inspect(from c in Car, where: c.age != ^42)
      assert query(~S|name != "a"|) == inspect(from c in Car, where: c.name != ^"a")
      assert query(~S|name != true|) == inspect(from c in Car, where: c.name != ^true)
      assert query(~S|null != null|) == inspect(from(c in Car, where: false))
      assert query(~S|42 != 42|) == inspect(from(c in Car, where: false))
      assert query(~S|name != null|) == inspect(from c in Car, where: not is_nil(c.name))
      assert query(~S|null != name|) == inspect(from c in Car, where: not is_nil(c.name))
    end

    test "ordering comparisons" do
      assert query(~S|age > 42|) == inspect(from c in Car, where: c.age > ^42)
      assert query(~S|age < 42|) == inspect(from c in Car, where: c.age < ^42)
      assert query(~S|age >= 42|) == inspect(from c in Car, where: c.age >= ^42)
      assert query(~S|age <= 42|) == inspect(from(c in Car, where: c.age <= ^42))
    end
  end

  describe "comparison with arithmetic" do
    test "basic operators" do
      assert query(~S|age > age + 42|) == inspect(from c in Car, where: c.age > c.age + ^42)
      assert query(~S|age > age - 42|) == inspect(from c in Car, where: c.age > c.age - ^42)
      assert query(~S|age > age * 42|) == inspect(from c in Car, where: c.age > c.age * ^42)
      assert query(~S|age > age / 42|) == inspect(from c in Car, where: c.age > c.age / ^42)
    end

    test "arithmetic precedence" do
      assert query(~S|age > (age + 42) * age - 42|) ==
               inspect(from c in Car, where: c.age > (c.age + ^42) * c.age - ^42)
    end
  end

  describe "filters on associated schemas" do
    test "comparisons" do
      assert query(~S|
                  brand.group.name == "some name" or
                  brand.value < 2 and
                  brand.group.value > 3|) ==
               inspect(
                 from c in Car,
                   join: brand in assoc(c, :brand),
                   as: :brand,
                   join: brand_group in assoc(brand, :group),
                   as: :brand_group,
                   where:
                     brand_group.name == ^"some name" or
                       (brand.value < ^2 and brand_group.value > ^3)
               )
    end
  end
end
