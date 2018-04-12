defmodule TransportWeb.Admin.DatasetController do
  use TransportWeb, :controller
  alias Transport.DataValidation
  alias Transport.ReusableData

  plug :set_project
  plug :set_dataset when action not in [:index]
  plug :set_feed_source when action not in [:index]

  def index(%Plug.Conn{} = conn, _params) do
    conn
    |> assign(:datasets, ReusableData.list_datasets)
    |> render("index.html")
  end

  def validate(%Plug.Conn{} = conn, %{"slug" => _}) do
    :ok =
      DataValidation.validate_feed_source(%{
        project: conn.assigns.project,
        feed_source: conn.assigns.feed_source
      })

    conn
    |> put_flash(:info, "Dataset being validated")
    |> redirect(to: admin_dataset_path(conn, :index))
    |> halt
  end

  def fetch_validation(%Plug.Conn{} = conn, %{"slug" => _}) do
    case conn.assigns.feed_source.latest_version_id do
      nil ->
        conn
        |> put_flash(:warning, "Dataset validation not (yet) fetched")
        |> redirect(to: admin_dataset_path(conn, :index))

      latest_version_id ->
        {:ok, feed_version} =
          DataValidation.find_feed_version(%{
            project: conn.assigns.project,
            latest_version_id: latest_version_id
          })

        :ok =
          ReusableData.update_dataset(
            conn.assigns.dataset,
            %{"catalogue_id" => feed_version.namespace}
          )

        conn
        |> put_flash(:success, "Yupii")
        |> redirect(to: admin_dataset_path(conn, :index))
        |> halt
    end
  end

  defp set_project(%Plug.Conn{} = conn, _options) do
    params = %{name: "transport"}

    {:ok, project} =
      case DataValidation.find_project(params) do
        {:ok, nil} -> DataValidation.create_project(params)
        {:ok, project} -> {:ok, project}
      end

    assign(conn, :project, project)
  end

  defp set_dataset(%Plug.Conn{} = conn, _options) do
    assign(conn, :dataset, ReusableData.get_dataset(conn.params["slug"]))
  end

  defp set_feed_source(%Plug.Conn{} = conn, _options) do
    params = %{
      project: conn.assigns.project,
      name: conn.params["slug"],
      url: conn.assigns.dataset.download_uri
    }

    {:ok, feed_source} =
      case DataValidation.find_feed_source(params) do
        {:ok, nil} -> DataValidation.create_feed_source(params)
        {:ok, feed_source} -> {:ok, feed_source}
      end

    assign(conn, :feed_source, feed_source)
  end
end
