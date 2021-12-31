defmodule EctoFilteringWeb.MoviesLive do
  @moduledoc false

  use EctoFilteringWeb, :live_view

  require Logger

  alias Ecto.Changeset
  alias EctoFiltering.Repo
  alias EctoFiltering.Schemas.Movie

  # def render(assigns) do
  #   ~H"""
  #   Current temperature: <%= @temperature %>
  #   """
  # end

  def mount(_params, _session, socket) do
    initial_socket =
      socket
      |> assign(:changeset, changeset(%{filter: ""}))
      |> assign(:sql, "")
      |> assign(:sql_args, [])
      |> assign(:movies, [])

    {:ok, initial_socket}
  end

  def handle_event("filter_changed", %{"filter" => params}, socket) do
    updated_socket =
      socket
      |> update_changeset(params)
      |> update_movies()

    {:noreply, updated_socket}
  end

  defp update_changeset(socket, params) do
    changeset =
      params
      |> changeset()
      |> Map.put(:action, :validate)

    IO.inspect(changeset)
    assign(socket, changeset: changeset)
  end

  def changeset(params) do
    data = %{}
    types = %{filter: :string, ast: :any}

    {data, types}
    |> Changeset.cast(params, [:filter])
    |> parse_filter()
  end

  def parse_filter(changeset) do
    filter = Changeset.get_field(changeset, :filter, "")

    case EctoFiltering.Parser.bexpr(filter) do
      {:ok, [ast], "", _, _, _} ->
        Changeset.put_change(changeset, :ast, ast)

      {:ok, [_ast], rem, _, _, _} ->
        error = "unable to parse: #{rem}"
        Changeset.add_error(changeset, :filter, error)

      {:error, reason, _, _, _, _} ->
        Changeset.add_error(changeset, :filter, reason)
    end
  end

  defp update_movies(socket) do
    %{ast: ast} = Changeset.apply_action!(socket.assigns[:changeset], :insert)
    query = EctoFiltering.Query.apply(Movie, ast)
    movies = Repo.all(query)
    {sql, args} = Ecto.Adapters.SQL.to_sql(:all, Repo, query)

    :age
    :founded
    :studio
    :studio_founded
    :director

    socket
    |> assign(:movies, movies)
    |> assign(:sql, sql)
    |> assign(:sql_args, args)
  rescue
    err ->
      Logger.error(inspect(err))
      socket
  end
end
