# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     EctoFiltering.Repo.insert!(%EctoFiltering.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias EctoFiltering.Repo
alias EctoFiltering.Schemas.Director
alias EctoFiltering.Schemas.Studio
alias EctoFiltering.Schemas.Movie

joe = %Director{name: "joe", age: 30} |> Repo.insert!()
max = %Director{name: "max", age: 30} |> Repo.insert!()
moe = %Director{name: "moe", age: 30} |> Repo.insert!()

gold = %Studio{name: "gold", founded: 1990} |> Repo.insert!()
silver = %Studio{name: "silver", founded: 2000} |> Repo.insert!()
bronze = %Studio{name: "bronze", founded: 2010} |> Repo.insert!()

for char <- ?a..?z,
    director <- [joe, max, moe],
    studio <- [gold, silver, bronze] do
  Repo.insert!(%Movie{
    name: List.to_string([char]),
    year: Enum.random(1990..2020),
    director_id: director.id,
    studio_id: studio.id
  })
end
