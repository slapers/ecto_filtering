defmodule EctoFiltering.Repo.Migrations.CreateDirector do
  use Ecto.Migration

  def change do
    create table(:directors) do
      add :name, :string
      add :age, :integer

      timestamps()
    end

    create index(:directors, [:name])
    create index(:directors, [:age])
    create index(:directors, [:inserted_at])
    create index(:directors, [:updated_at])
  end
end
