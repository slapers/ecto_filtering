defmodule EctoFiltering.Repo.Migrations.CreateMovies do
  use Ecto.Migration

  def change do
    create table(:movies) do
      add :name, :string
      add :year, :integer
      add :studio_id, references(:studios, on_delete: :nothing)
      add :director_id, references(:directors, on_delete: :nothing)

      timestamps()
    end

    create index(:movies, [:name])
    create index(:movies, [:year])
    create index(:movies, [:studio_id])
    create index(:movies, [:director_id])
    create index(:movies, [:inserted_at])
    create index(:movies, [:updated_at])
  end
end
