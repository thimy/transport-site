defmodule TransportWeb.Router do
  use TransportWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_locale
    plug :assign_current_user
    plug :assign_contact_email
    plug :assign_token
  end

  pipeline :json_api do
    plug :accepts, ["jsonapi"]
    plug JaSerializer.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  pipeline :accept_json do
    plug :accepts, ["json"]
  end

  pipeline :api_authenticated do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
    plug :assign_current_user
    plug :assign_token
    plug :authentication_required
  end

  pipeline :admin_rights do
    plug :fetch_session
    plug :fetch_flash
    plug :assign_current_user
    plug :authentication_required
    plug :transport_data_gouv_member
  end

  scope "/", TransportWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/stats", StatsController, :index
    post "/send_mail", ContactController, :send_mail

    scope "/datasets" do
      get "/", DatasetController, :index
      get "/:slug/", DatasetController, :details
      get "/aom/:commune", DatasetController, :by_aom
      get "/region/:region", DatasetController, :by_region
      get "/type/:type", DatasetController, :by_type
    end

    scope "/backoffice" do
      pipe_through [:admin_rights]
      get "/", BackofficeController, :index
      post "/", BackofficeController, :new_dataset
      post "/datasets/:id/_import", BackofficeController, :import_from_data_gouv_fr
      post "/datasets/:id/_delete", BackofficeController, :delete
    end

    # Authentication

    scope "/login" do
      get "/", SessionController, :new
      get "/explanation", PageController, :login
      get "/callback", SessionController, :create
    end

    get "/logout", SessionController, :delete

    # If nothing else matches, it’s probably a dummy single page
    get "/:page", PageController, :single_page
  end

  scope "/api", TransportWeb do

    scope "/datasets/:dataset_id/followers" do
      pipe_through :api_authenticated
      post "/", API.FollowerController, :create
      delete "/", API.FollowerController, :delete
    end

    scope "/discussions" do
      pipe_through :api_authenticated
      post "/", API.DiscussionController, :post_discussion
      post "/:id_", API.DiscussionController, :post_discussion
    end

    scope "/stats" do
      pipe_through :accept_json
      get "/", API.StatsController, :index
      get "/regions", API.StatsController, :regions
    end
  end

  # private

  defp put_locale(conn, _) do
    case conn.params["locale"] || get_session(conn, :locale) do
      nil ->
        TransportWeb.Gettext |> Gettext.put_locale("fr")
        conn |> put_session(:locale, "fr")
      locale  ->
        TransportWeb.Gettext |> Gettext.put_locale(locale)
        conn |> put_session(:locale, locale)
    end
  end

  defp assign_current_user(conn, _) do
    assign(conn, :current_user, get_session(conn, :current_user))
  end

  defp assign_contact_email(conn, _) do
    assign(conn, :contact_email, "contact@transport.beta.gouv.fr")
  end

  defp assign_token(conn, _) do
    assign(conn, :token, get_session(conn, :token))
  end

  defp authentication_required(conn, _) do
    case conn.assigns[:current_user]  do
      nil ->
        conn
            |> put_flash(:info, dgettext("alert", "You need to be connected before doing this."))
            |> redirect(to: Helpers.page_path(conn, :login,
                        redirect_path: current_path(conn)))
            |> halt()
      _ ->
        conn
    end
  end

  defp transport_data_gouv_member(conn, _) do
    conn.assigns[:current_user]
    |> Map.get("organizations", [])
    |> Enum.any?(fn org -> org["slug"] == "equipe-transport-data-gouv-fr" end)
    |> if do
        conn
       else
        conn
        |> put_flash(:error, dgettext("alert", "You need to be a member of the transport.data.gouv.fr team."))
        |> redirect(to: Helpers.page_path(conn, :login,
                    redirect_path: current_path(conn)))
        |> halt()
       end
  end
end
