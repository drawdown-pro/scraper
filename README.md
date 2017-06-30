# scraper

Scrapes the drawdown website and seed the platform database.

Strategy to seed the initial platform database is to scrape the [solution summary table](http://www.drawdown.org/solutions-summary-by-rank) and create an index for these solutions. Keeping the numbers/urls in synch with the main database of companies/organizations.

#### technology

* elixir
* postgresql/cockroach

#### build

    $ mix deps.get
    $ mix compile

#### test

    $ mix test

#### run

    $ elixir -S mix run -e Scraper.run

