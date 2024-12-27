defmodule TaskMasterWeb.HighScoreLive do
  use TaskMasterWeb, :live_view
  alias TaskMaster.Accounts

  def render(assigns) do
    ~H"""
    <.table id="high_score" rows={@all_users}>
      <:col :let={user} label="Who"><%= user.nick_name %></:col>
      <:col :let={user} label="🌟"><%= user.stars %></:col>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    all_users = Accounts.get_users_with_stars(socket.assigns.current_user.organization_id)

    socket
    |> assign(:all_users, all_users)
    |> ok()
  end
end
