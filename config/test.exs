use Mix.Config

config :scraper,
  storage: CouchStorage,
  couch: %{protocol: "http", hostname: "localhost", database: "drawdown-pro", port: 5984},
  graphql: %{
    endpoint: System.get_env("GRAPHQL_ENDPOINT"),
    token: System.get_env("GRAPHQL_TOKEN")
  }
