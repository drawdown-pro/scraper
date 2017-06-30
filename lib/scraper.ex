defmodule Scraper do
  @moduledoc """
  Documentation for Scraper.
  """

  def extract_cell_text(cell) do
    Floki.text(cell)
      |> String.replace(~r/(^\s+|\s+$)/, "")
  end

  def extract_solution_data(cells) do
    solution_url = Floki.attribute(Floki.find(cells, "a"), "href")
    List.zip([[:rank, :solution, :sector, :reduction, :cost, :savings], cells])
      |> Enum.reduce(%{solution_url: solution_url}, fn(cell, data) ->
          Map.put(data, elem(cell,0), extract_cell_text(elem(cell,1)))
        end)
  end

  def process_solutions(cells) do
    Enum.chunk(cells, 6)
      |> Enum.map(&(extract_solution_data(&1)))
      |> Enum.map(fn(solution) ->
        Couchdb.Connector.Writer.create(Application.get_env(:scraper, :db), Poison.encode!(solution), solution[:rank])
        |> IO.inspect
      end)
  end

  @doc """


  ## Examples

      $ elixir -S mix run -e Scraper.run


  """

  def run do
    url = "http://www.drawdown.org/solutions-summary-by-rank"
    body = HTTPoison.get!(url, []).body
    solution_rows = Floki.find(body, "div.solutions-table")

    solution_rows
      |> Floki.raw_html
      |> Floki.find("tr td")
      |> process_solutions
  end
end

