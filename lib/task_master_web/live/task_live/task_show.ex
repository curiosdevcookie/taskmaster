defmodule TaskMasterWeb.TaskLive.TaskShow do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Tasks

  import TaskMasterWeb.Components.TaskComponents

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Tasks.subscribe(socket.assigns.current_user.organization_id)
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    org_id = socket.assigns.current_user.organization_id
    task = Tasks.get_task!(id, org_id) |> Tasks.preload_task_participants()

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:task, task)}
  end

  @impl true
  def handle_info({:task_updated, updated_task}, socket) do
    if updated_task.id == socket.assigns.task.id do
      {:noreply, assign(socket, :task, updated_task)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:task_deleted, deleted_task}, socket) do
    if deleted_task.id == socket.assigns.task.id do
      {:noreply,
       socket
       |> put_flash(:info, "This task has been deleted.")
       |> push_navigate(to: ~p"/#{socket.assigns.current_user.id}/tasks")}
    else
      {:noreply, socket}
    end
  end

  defp page_title(:show), do: "Show Task"
  defp page_title(:edit), do: "Edit Task"

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= gettext("Task") %>
      <:subtitle><%= gettext("This is a task record from your database.") %></:subtitle>
      <:actions>
        <.link patch={~p"/#{@current_user.id}/tasks/#{@task}/show/edit"} phx-click={JS.push_focus()}>
          <.button><%= gettext("Edit task") %></.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title={gettext("Title")}><%= @task.title %></:item>
      <:item title={gettext("Description")}><%= @task.description %></:item>
      <:item title={gettext("Due date")}><%= @task.due_date %></:item>
      <:item title={gettext("Status")}>
        <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(@task.status) %>
      </:item>
      <:item title={gettext("Duration")}><%= @task.duration %></:item>
      <:item title={gettext("Priority")}>
        <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(@task.priority) %>
      </:item>
      <:item title={gettext("Indoor")}>
        <%= TaskMasterWeb.Helpers.IconHelper.boolean_icon(@task.indoor) %>
      </:item>
      <:item title={gettext("Who?")}>
        <div class="flex flex-wrap gap-2">
          <%= for participant <- @task.participants do %>
            <.nick_name participant={participant.nick_name} />
          <% end %>
        </div>
      </:item>
    </.list>

    <.back navigate={~p"/#{@current_user.id}/tasks"}><%= gettext("Back") %></.back>

    <.modal
      :if={@live_action == :edit}
      id="task-modal"
      show
      on_cancel={JS.patch(~p"/#{@current_user.id}/tasks/#{@task}")}
    >
      <.live_component
        module={TaskMasterWeb.TaskLive.TaskComponent}
        id={@task.id}
        title={@page_title}
        action={@live_action}
        task={@task}
        current_user={@current_user}
        patch={~p"/#{@current_user.id}/tasks/#{@task}"}
      />
    </.modal>
    """
  end
end
