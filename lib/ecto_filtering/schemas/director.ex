defmodule EctoFiltering.Schemas.Director do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias EctoFiltering.Schemas.Movie

  schema "directors" do
    field :name, :string
    field :age, :integer
    has_many :movies, Movie
    timestamps()
  end

  @doc false
  def changeset(director, attrs) do
    director
    |> cast(attrs, [:name, :age])
    |> validate_required([:name, :age])
  end
end
