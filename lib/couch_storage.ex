

defmodule CouchStorage do
  @moduledoc """
  Documentation for CouchStorage.
  """
  def initialize do
  end

  def run_mango_query(query) do
    db_url = Couchdb.Connector.UrlHelper.database_url(Application.get_env(:scraper, :couch))
    HTTPoison.post!("#{db_url}/_find", query, [Couchdb.Connector.Headers.json_header()])
      |> Couchdb.Connector.ResponseHandler.handle_get
  end

  def decode_solution({:ok, body}) do
    %{"docs" => docs} = Poison.decode!(body)
    {:ok, List.first(docs)}
  end

  def decode_solution({:error, body}) do
    {:error, Poison.decode!(body)}
  end

  def find_solution_by_rank(rank) do
    run_mango_query("{\"selector\":{\"rank\":#{rank}}}")
      |> decode_solution
  end

  def save_solution(solution) do
    solution_doc = Map.put(solution, :type, "drawdown:solution")
    case Couchdb.Connector.Writer.create_generate(Application.get_env(:scraper, :couch), Poison.encode!(solution_doc)) do
      {:ok, _, _} ->
        {:ok, "Added."}
      {:error, body, _} ->
        {:error, "ERROR: #{body}"}
    end
  end

end
