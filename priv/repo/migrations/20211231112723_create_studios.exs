defmodule EctoFiltering.Repo.Migrations.CreateStudios do
  use Ecto.Migration

  def change do
    create table(:studios) do
      add :name, :string
      add :founded, :integer

      timestamps()
    end

    create index(:studios, [:name])
    create index(:studios, [:founded])
    create index(:studios, [:inserted_at])
    create index(:studios, [:updated_at])
  end
end
