defmodule TaskMasterWeb.TaskLive.TaskIndex do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Tasks
  alias TaskMaster.Tasks.Task
  import TaskMasterWeb.Components.TaskComponents

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    tasks = Tasks.list_tasks_with_participants(current_user.organization_id)

    parent_tasks = Tasks.list_parent_tasks(current_user.organization_id)
    subtasks = Tasks.list_subtasks(current_user.organization_id)

    if connected?(socket) do
      Tasks.subscribe(current_user.organization_id)
    end

    socket
    |> assign(:current_user, current_user)
    |> assign(:page_title, gettext("Listing Tasks"))
    |> stream(:tasks, tasks)
    |> assign(:parent_tasks, parent_tasks)
    |> assign(:subtasks, subtasks)
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    org_id = socket.assigns.current_user.organization_id
    task = Tasks.get_task!(id, org_id)

    socket
    |> assign(:page_title, gettext("Edit Task"))
    |> assign(:task, task)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Task"))
    |> assign(:task, %Task{organization_id: socket.assigns.current_user.organization_id})
  end

  defp apply_action(socket, :new_subtask, %{"parent_id" => parent_id}) do
    org_id = socket.assigns.current_user.organization_id
    parent_task = Tasks.get_task!(parent_id, org_id)

    socket
    |> assign(:page_title, gettext("New Subtask"))
    |> assign(:task, %Task{
      parent_task_id: parent_id,
      organization_id: org_id
    })
    |> assign(:parent_task, parent_task)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Tasks"))
    |> assign(:task, nil)
  end

  @impl true
  def handle_info({TaskMasterWeb.TaskLive.TaskComponent, {:saved, task}}, socket) do
    org_id = socket.assigns.current_user.organization_id
    updated_task = Tasks.get_task!(task.id, org_id) |> Tasks.preload_task_participants()

    {:noreply,
     socket
     |> stream_insert(:tasks, updated_task)
     |> push_patch(to: ~p"/#{socket.assigns.current_user.id}/tasks")}
  end

  @impl true
  def handle_info({:task_created, task}, socket) do
    {:noreply, stream_insert(socket, :tasks, task)}
  end

  @impl true
  def handle_info({:task_updated, task}, socket) do
    {:noreply, stream_insert(socket, :tasks, task)}
  end

  @impl true
  def handle_info({:task_deleted, task}, socket) do
    {:noreply, stream_delete(socket, :tasks, task)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    org_id = socket.assigns.current_user.organization_id
    task = Tasks.get_task!(id, org_id)
    {:ok, _} = Tasks.delete_task(task, org_id)

    {:noreply, stream_delete(socket, :tasks, task)}
  end

  @impl true
  def handle_event("add_subtask", %{"parent_id" => parent_id}, socket) do
    org_id = socket.assigns.current_user.organization_id
    parent_id |> dbg()
    parent_task = Tasks.get_task!(parent_id, org_id)

    {:noreply,
     socket
     |> assign(:parent_task, parent_task)
     |> assign(:page_title, gettext("New Subtask"))
     |> push_patch(to: ~p"/#{socket.assigns.current_user.id}/tasks/#{parent_task.id}/new_subtask")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= gettext("Listing Tasks") %>
      <:actions>
        <.link patch={~p"/#{@current_user.id}/tasks/new"}>
          <.button class="btn-primary"><%= gettext("New Task") %></.button>
        </.link>
      </:actions>
    </.header>
    <div class="flex flex-col gap-4">
      <%= for parent_task <- @parent_tasks do %>
        <div class="border border-gray-600 p-2 rounded-lg p-4">
          <div class="flex items-center gap-2">
            <.icon name="hero-chevron-double-right" />
            <.link navigate={~p"/#{@current_user.id}/tasks/#{parent_task}"}>
              <%= parent_task.title %>
            </.link>
          </div>

          <.link patch={~p"/#{@current_user.id}/tasks/#{parent_task.id}/new_subtask"}>
            <.button
              class="btn-secondary"
              phx-click={JS.push("add_subtask", value: %{parent_id: parent_task.id})}
            >
              <.icon name="hero-plus" />
            </.button>
          </.link>
          <div class="flex flex-col gap-2">
            <%= for subtask <- Enum.filter(@subtasks, & &1.parent_task_id == parent_task.id) do %>
              <.link navigate={~p"/#{@current_user.id}/tasks/#{subtask}"}>
                <%= subtask.title %>
              </.link>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    <.table
      id="tasks"
      rows={@streams.tasks}
      row_click={fn {_id, task} -> JS.navigate(~p"/#{@current_user.id}/tasks/#{task}") end}
    >
      <:col :let={{_id, task}} label={gettext("Title")}><%= task.title %></:col>
      <:col :let={{_id, task}} label={gettext("Description")}><%= task.description %></:col>
      <:col :let={{_id, task}} label={gettext("Due date")}><%= task.due_date %></:col>
      <:col :let={{_id, task}} label={gettext("Status")}>
        <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(task.status) %>
      </:col>
      <:col :let={{_id, task}} label={gettext("Duration in minutes")}>
        <%= TaskMasterWeb.Helpers.Formatted.format_duration(task.duration) %>
      </:col>
      <:col :let={{_id, task}} label={gettext("Priority")}>
        <%= TaskMasterWeb.Helpers.EnumTranslator.translate_enum_value(task.priority) %>
      </:col>
      <:col :let={{_id, task}} label={gettext("Indoor")}>
        <%= TaskMasterWeb.Helpers.IconHelper.boolean_icon(task.indoor) %>
      </:col>
      <:col :let={{_id, task}} label={gettext("Who?")}>
        <div class="flex flex-wrap gap-1">
          <%= for participant <- Enum.sort_by(task.participants, & &1.nick_name) do %>
            <.nick_name participant={participant.nick_name} />
          <% end %>
        </div>
      </:col>
      <:action :let={{_id, task}}>
        <%!-- SUBTASKS --%>
        <.link patch={~p"/#{@current_user.id}/tasks/#{task.id}/new_subtask"}>
          <.button
            class="btn-secondary"
            phx-click={JS.push("add_subtask", value: %{parent_id: task.id})}
          >
            <.icon name="hero-plus" />
          </.button>
        </.link>
      </:action>
      <:action :let={{_id, task}}>
        <div class="sr-only">
          <.link navigate={~p"/#{@current_user.id}/tasks/#{task}"}><%= gettext("Show") %></.link>
        </div>
        <.link patch={~p"/#{@current_user.id}/tasks/#{task}/edit"}><%= gettext("Edit") %></.link>
      </:action>
      <:action :let={{id, task}}>
        <.link
          phx-click={JS.push("delete", value: %{id: task.id}) |> hide("##{id}")}
          data-confirm={gettext("Are you sure?")}
        >
          <%= gettext("Delete") %>
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit, :new_subtask]}
      id="task-modal"
      show
      on_cancel={JS.patch(~p"/#{@current_user.id}/tasks")}
    >
      <.live_component
        module={TaskMasterWeb.TaskLive.TaskComponent}
        id={@task.id || :new}
        title={@page_title}
        action={@live_action}
        task={@task}
        parent_id={{@task.parent_task_id, @task.id}}
        current_user={@current_user}
        patch={~p"/#{@current_user.id}/tasks"}
      />
    </.modal>
    """
  end
end
