defmodule TaskMasterWeb.AvatarLive.UploadLive do
  use TaskMasterWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    # Handle the save event
    {:noreply, socket}
  end
end
