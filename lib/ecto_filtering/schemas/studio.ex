defmodule EctoFiltering.Schemas.Studio do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias EctoFiltering.Schemas.Movie

  schema "studios" do
    field :name, :string
    field :founded, :integer
    has_many :movies, Movie
    timestamps()
  end

  @doc false
  def changeset(studio, attrs) do
    studio
    |> cast(attrs, [:name, :founded])
    |> validate_required([:name, :founded])
  end
end
