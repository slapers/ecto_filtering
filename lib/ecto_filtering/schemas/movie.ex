defmodule EctoFiltering.Schemas.Movie do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias EctoFiltering.Schemas.Director
  alias EctoFiltering.Schemas.Studio

  schema "movies" do
    field :name, :string
    field :year, :integer
    belongs_to :director, Director
    belongs_to :studio, Studio
    timestamps()
  end

  @doc false
  def changeset(movie, attrs) do
    movie
    |> cast(attrs, [:name, :year])
    |> validate_required([:name, :year])
  end
end
