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
    List.zip([[:rank, :title, :sector, :reduction, :cost, :savings], cells])
      |> Enum.reduce(%{urls: solution_url}, fn(cell, data) ->
          Map.put(data, elem(cell,0), extract_cell_text(cell))
        end)
  end

  # def run_mango_query(query) do
  #   db_url = Couchdb.Connector.UrlHelper.database_url(Application.get_env(:scraper, :db))
  #   HTTPoison.post!("#{db_url}/_find", query, [Couchdb.Connector.Headers.json_header()])
  #     |> Couchdb.Connector.ResponseHandler.handle_get
  # end

  # def find_by_rank(rank, storage) do
  #   {result, body} = run_mango_query("{\"selector\":{\"rank\":#{rank}}}")
  #   {result, Poison.decode!(body)}
  # end

  def insert_solution({:ok, nil}, storage, solution) do
    {_, msg} = storage.save_solution(solution)
    msg
  end

  def insert_solution({:ok, _}, _, _) do
    "Solution exists."
  end

  def insert_solution({:error, msg}, _, _) do
    "ERROR looking up solution: #{msg}"
  end

  def process_solutions(cells, storage) do
    Enum.chunk(cells, 6)
      |> Enum.map(&(extract_solution_data(&1)))
      |> Enum.map(fn(solution) ->
        IO.puts "#{solution[:rank]} - #{solution[:title]}\n> "
        storage.find_solution_by_rank(solution[:rank])
          |> insert_solution(storage, solution)
          |> IO.puts
        IO.puts String.duplicate("-", 80)
      end)
  end

  @doc """


  ## Examples

      $ elixir -S mix run -e Scraper.run


  """

  def run do
    storage = Application.get_env(:scraper, :storage)
    storage.initialize
    url = "http://www.drawdown.org/solutions-summary-by-rank"
    body = HTTPoison.get!(url, []).body
    File.write("./log/solutions-summary-by-rank-#{Timex.format!(Timex.local, "{ISOdate}")}.html", body, [:utf8])
    solution_rows = Floki.find(body, "div.solutions-table")

    solution_rows
      |> Floki.raw_html
      |> Floki.find("tr td")
      |> process_solutions(storage)
  end
end

