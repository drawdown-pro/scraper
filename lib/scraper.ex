use Timex

defmodule Scraper do
  @moduledoc """
  Documentation for Scraper.
  """

  def extract_cell_text(cell) do
    val = Floki.text(elem(cell, 1))
      |> String.replace(~r/(^\s+|\$|,|\s+$)/, "")
    key = elem(cell, 0)
    cond do
      key == :rank ->
        String.to_integer(val)
      val == "N/A" ->
        nil
      MapSet.member?(MapSet.new([:reduction, :cost, :savings]), key) -> 
        String.to_float(val)
      true ->
        val
    end
  end

  def extract_solution_data(cells) do
    solution_url = Floki.attribute(Floki.find(cells, "a"), "href")
    List.zip([[:rank, :solution, :sector, :reduction, :cost, :savings], cells])
      |> Enum.reduce(%{solution_url: solution_url}, fn(cell, data) ->
          Map.put(data, elem(cell,0), extract_cell_text(cell))
        end)
  end

  def run_mango_query(query) do
    db_url = Couchdb.Connector.UrlHelper.database_url(Application.get_env(:scraper, :db))
    HTTPoison.post!("#{db_url}/_find", query, [Couchdb.Connector.Headers.json_header()])
      |> Couchdb.Connector.ResponseHandler.handle_get
  end

  def find_by_rank(rank) do
    {result, body} = run_mango_query("{\"selector\":{\"rank\":#{rank}}}")
    {result, Poison.decode!(body)}
  end

  def process_solutions(cells) do
    Enum.chunk(cells, 6)
      |> Enum.map(&(extract_solution_data(&1)))
      |> Enum.map(fn(solution) ->
        "#{solution[:rank]} - #{solution[:solution]}\n> " <>
        case find_by_rank(solution[:rank]) do
          {:ok, %{"docs" => []}} ->
            case Couchdb.Connector.Writer.create_generate(Application.get_env(:scraper, :db), Poison.encode!(solution)) do
              {:ok, _} ->
                "Added."
              {:error, body} ->
                "ERROR: #{body}"
            end
          {:ok, _} ->
            "Solution exists."
          {:error, body} ->
            "ERROR looking up solution: #{body}"
        end |> IO.puts 
        IO.puts String.duplicate("-", 80)
      end)
  end

  @doc """


  ## Examples

      $ elixir -S mix run -e Scraper.run


  """

  def run do
    url = "http://www.drawdown.org/solutions-summary-by-rank"
    body = HTTPoison.get!(url, []).body
    File.write("./solutions-summary-by-rank-#{Timex.format!(Timex.local, "{ISOdate}")}.html", body, [:utf8])
    solution_rows = Floki.find(body, "div.solutions-table")

    solution_rows
      |> Floki.raw_html
      |> Floki.find("tr td")
      |> process_solutions
  end
end

