defmodule EctoFiltering.Repo do
  use Ecto.Repo,
    otp_app: :ecto_filtering,
    adapter: Ecto.Adapters.Postgres
end
