
defmodule GraphQLStorage do
  @moduledoc """
  Documentation for GraphQLStorage.
  """
  def initialize do
    graphql_config = Application.get_env(:scraper, :graphql)
    Neuron.Config.set(url: graphql_config[:endpoint])
    Neuron.Config.set(headers: [
      "Content-Type": "application/json",
      "Authorization": "Bearer #{graphql_config[:token]}"
    ])
  end

  def decode_solution({:ok, %{body: nil}}) do
    {:ok, nil}
  end

  def decode_solution({:ok, %{body: body}}) do
    {:ok, Map.get(body, "Solution")}
  end

  def decode_solution({:error, %{body: error_msg}}) do
    {:error, error_msg}
  end

  def find_solution_by_rank(rank) do
    Neuron.query(~s"""
      {
        Solution(rank: #{rank}) {
          id
          rank
          title
        }
      }
    """)
      |> decode_solution    
  end

  def solution_saved({:ok, %{status_code: 200, body: %{"createSolution" => %{"id" => id}}}}) do
    {:ok, "Solution inserted: #{id}"}
  end

  def solution_saved({_, %{status_code: status_code, body: body}}) do
    {:error, "status: #{status_code} body: #{inspect(body)}"}
  end

  def save_solution(solution) do
    solution_values = Enum.join(Enum.map(solution, fn({k,v}) -> 
      val = if (v == nil), do: "null", else: inspect(v)
      "#{k}: #{val}" 
    end), ", ")
    # replace "nil" with "null"
    IO.puts "adding solution:\n#{solution_values}"
    Neuron.mutation(~s"""
      {
        createSolution (
          #{solution_values}
        ){
          id
        }
      }
    """)
      |> solution_saved
  end

end
