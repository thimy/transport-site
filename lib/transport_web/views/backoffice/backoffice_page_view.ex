defmodule TransportWeb.Backoffice.BackofficePageView do
  use TransportWeb, :view
  import TransportWeb.PaginationHelpers
  import TransportWeb.DatasetView, only: [first_gtfs: 1]
end