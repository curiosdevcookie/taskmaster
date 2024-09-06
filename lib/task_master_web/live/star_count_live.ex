defmodule TaskMasterWeb.StarCountLive do
  use TaskMasterWeb, :live_view
  alias TaskMaster.Accounts

  def render(assigns) do
    ~H"""
    <svg
      id="b"
      xmlns="http://www.w3.org/2000/svg"
      class="sm:w-6 sm:h-6 lg:w-12 lg:h-12"
      viewBox="0 0 12 12.4"
    >
      <defs>
        <style>
          .d{fill:#ffdf85;}.d,.e{stroke-width:0px;}.e{fill:#ffce31;}
        </style>
      </defs>
      <g id="c">
        <polygon
          class="e"
          points="11.6 4.7 7.3 4.7 6 .7 4.7 4.7 .4 4.7 3.9 7.1 2.5 11 6 8.6 9.5 11 8.1 7.1 11.6 4.7"
        /><polygon class="d" points="8.7 4.2 9.4 2 7.4 3.4 7.7 4.2 8.7 4.2" /><polygon
          class="d"
          points="5.2 9.7 6 12 6.8 9.7 6 9.2 5.2 9.7"
        /><polygon class="d" points="9.5 6.8 8.8 7.3 9.1 8.2 11.5 8.2 9.5 6.8" /><polygon
          class="d"
          points="4.6 3.4 2.6 2 3.3 4.2 4.3 4.2 4.6 3.4"
        /><polygon class="d" points="2.5 6.8 .5 8.2 2.9 8.2 3.2 7.3 2.5 6.8" />
      </g>
      <text
        x="50%"
        y="55%"
        dominant-baseline="middle"
        text-anchor="middle"
        fill="blue"
        font-size="3"
        font-weight="bold"
      >
        <%= @stars %>
      </text>
    </svg>
    """
  end

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      TaskMasterWeb.Endpoint.subscribe("task_updates")
    end

    user = Accounts.get_user!(user_id)
    {:ok, assign(socket, stars: user.stars, user_id: user_id)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "task_updated", payload: updated_task}, socket) do
    if task_involves_user?(updated_task, socket.assigns.user_id) do
      user = Accounts.get_user!(socket.assigns.user_id)
      {:noreply, assign(socket, stars: user.stars)}
    else
      {:noreply, socket}
    end
  end

  defp task_involves_user?(task, user_id) do
    Enum.any?(task.task_participations, fn participation ->
      participation.user_id == user_id
    end)
  end
end
