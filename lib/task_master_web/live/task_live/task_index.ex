defmodule TaskMasterWeb.TaskLive.TaskIndex do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Tasks
  alias TaskMaster.Tasks.Task
  import TaskMasterWeb.Components.TaskComponents

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user

    tasks = Tasks.list_tasks_with_participants(current_user.organization_id)
    parent_tasks = Tasks.list_parent_tasks(current_user.organization_id)
    subtasks = Tasks.list_subtasks(current_user.organization_id)

    parent_tasks = Enum.map(parent_tasks, &Tasks.preload_task_participants/1)
    subtasks = Enum.map(subtasks, &Tasks.preload_task_participants/1)

    {completed_parent_tasks, open_parent_tasks} =
      Enum.split_with(parent_tasks, &(&1.status == :completed))

    sort_by = params["sort_by"] || "title"
    sort_order = params["sort_order"] || "asc"

    sorted_tasks = sort_tasks(tasks, sort_by, sort_order)

    if connected?(socket) do
      Tasks.subscribe(current_user.organization_id)
    end

    socket
    |> assign(:current_user, current_user)
    |> assign(:page_title, gettext("Listing Tasks"))
    |> assign(:sort_by, sort_by)
    |> assign(:sort_order, sort_order)
    |> stream(:tasks, sorted_tasks)
    |> assign(:selected, "")
    |> assign(:open_parent_tasks, sort_tasks(open_parent_tasks, sort_by, sort_order))
    |> assign(:completed_parent_tasks, sort_tasks(completed_parent_tasks, sort_by, sort_order))
    |> assign(:subtasks, sort_tasks(subtasks, sort_by, sort_order))
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    sort_by = params["sort_by"] || "title"
    sort_order = params["sort_order"] || "asc"

    socket
    |> assign(:sort_by, sort_by)
    |> assign(:sort_order, sort_order)
    |> update_sorted_tasks()
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
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
  def handle_info({:task_created, new_task}, socket) do
    {:noreply, update_task_in_assigns(socket, new_task)}
  end

  @impl true
  def handle_info({:task_updated, updated_task}, socket) do
    org_id = socket.assigns.current_user.organization_id

    # Refresh the updated task
    refreshed_task = Tasks.get_task!(updated_task.id, org_id) |> Tasks.preload_task_participants()

    # If it's a subtask, also refresh its parent
    parent_task =
      if refreshed_task.parent_task_id do
        Tasks.get_task!(refreshed_task.parent_task_id, org_id)
        |> Tasks.preload_task_participants()
      end

    socket = update_task_in_assigns(socket, refreshed_task)

    socket =
      if parent_task do
        update_task_in_assigns(socket, parent_task)
      else
        socket
      end

    {:noreply, socket}
  end

  defp update_task_in_assigns(socket, updated_task) do
    socket
    |> stream_insert(:tasks, updated_task)
    |> update_parent_tasks(updated_task)
    |> update_subtasks(updated_task)
  end

  defp update_parent_tasks(socket, updated_task) do
    if is_nil(updated_task.parent_task_id) do
      {open_parent_tasks, completed_parent_tasks} =
        (socket.assigns.open_parent_tasks ++ socket.assigns.completed_parent_tasks)
        |> Enum.map(fn task ->
          if task.id == updated_task.id, do: updated_task, else: task
        end)
        |> Enum.split_with(&(&1.status != :completed))

      socket
      |> assign(:open_parent_tasks, open_parent_tasks)
      |> assign(:completed_parent_tasks, completed_parent_tasks)
    else
      socket
    end
  end

  defp update_subtasks(socket, updated_task) do
    socket
    |> update(:subtasks, fn tasks ->
      Enum.map(tasks, fn task ->
        if task.id == updated_task.id, do: updated_task, else: task
      end)
    end)
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
  def handle_event(
        "toggle_task_status",
        %{"id" => id, "current_status" => current_status},
        socket
      ) do
    org_id = socket.assigns.current_user.organization_id
    task = Tasks.get_task!(id, org_id)

    new_status = if current_status == "completed", do: "open", else: "completed"

    case Tasks.update_task(task, %{status: new_status}, task.participants, org_id) do
      {:ok, _updated_task} ->
        {:noreply, socket}

      {:error, :subtasks_not_completed} ->
        {:noreply,
         put_flash(socket, :error, "Cannot complete task: not all subtasks are completed")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update task status")}
    end
  end

  @impl true
  def handle_event("sort_tasks", %{"sort_by" => sort_by, "sort_order" => _sort_order}, socket) do
    new_sort_order =
      if sort_by == socket.assigns.sort_by && socket.assigns.sort_order == "asc",
        do: "desc",
        else: "asc"

    socket
    |> assign(:sort_by, sort_by)
    |> assign(:sort_order, new_sort_order)
    |> assign(:selected, sort_by)
    |> update_sorted_tasks()
    |> push_patch(
      to:
        ~p"/#{socket.assigns.current_user.id}/tasks?sort_by=#{sort_by}&sort_order=#{new_sort_order}"
    )
    |> noreply()
  end

  defp update_sorted_tasks(socket) do
    %{sort_by: sort_by, sort_order: sort_order} = socket.assigns

    socket
    |> update(:open_parent_tasks, &sort_tasks(&1, sort_by, sort_order))
    |> update(:completed_parent_tasks, &sort_tasks(&1, sort_by, sort_order))
    |> update(:subtasks, &sort_tasks(&1, sort_by, sort_order))
  end

  defp sort_tasks(tasks, sort_by, sort_order) do
    Enum.sort_by(tasks, &sort_value(&1, sort_by), sort_order_to_comparator(sort_order))
  end

  defp sort_value(task, sort_by) do
    case sort_by do
      "title" -> task.title
      "status" -> task.status
      "duration" -> task.duration
      "priority" -> task.priority
      "indoor" -> task.indoor
      "participants" -> length(task.participants)
      "due_date" -> task.due_date
      _ -> task.title
    end
  end

  defp sort_order_to_comparator("desc"), do: &>=/2
  defp sort_order_to_comparator(_), do: &<=/2

  @impl true
  def render(assigns) do
    ~H"""
    <section class="flex gap-1 my-4">
      <.sort_button
        selected={@selected}
        label={gettext("Title")}
        sort_by="title"
        sort_order={@sort_order}
        id="title"
      />
      <.sort_button
        selected={@selected}
        label={gettext("Due Date")}
        sort_by="due_date"
        sort_order={@sort_order}
        id="due_date"
      />
      <.sort_button
        selected={@selected}
        label={gettext("Duration")}
        sort_by="duration"
        sort_order={@sort_order}
        id="duration"
      />
      <.sort_button
        selected={@selected}
        label={gettext("Priority")}
        sort_by="priority"
        sort_order={@sort_order}
        id="priority"
      />
      <.sort_button
        selected={@selected}
        label={gettext("Indoor")}
        sort_by="indoor"
        sort_order={@sort_order}
        id="indoor"
      />
    </section>
    <div class="h-[calc(100vh-10rem)] flex flex-col gap-10">
      <div class="2/3 overflow-hidden pb-20">
        <.header class="mb-2">
          <p>
            <%= gettext("Open Tasks") %>
          </p>

          <:actions>
            <.link patch={~p"/#{@current_user.id}/tasks/new"}>
              <.button class="btn-primary"><%= gettext("New Task") %></.button>
            </.link>
          </:actions>
        </.header>

        <div class="h-full overflow-y-auto">
          <.task_list
            parent_tasks={@open_parent_tasks}
            subtasks={@subtasks}
            current_user={@current_user}
            navigate_fn={fn parent_task -> ~p"/#{@current_user.id}/tasks/#{parent_task}" end}
            patch_fn={
              fn parent_task -> ~p"/#{@current_user.id}/tasks/#{parent_task.id}/new_subtask" end
            }
          />
        </div>
      </div>
      <div class="1/3 overflow-hidden pb-20">
        <.footer class="mb-4">
          <p><%= gettext("Completed Tasks") %></p>
        </.footer>

        <div class="h-full overflow-y-auto">
          <.task_list
            parent_tasks={@completed_parent_tasks}
            subtasks={@subtasks}
            current_user={@current_user}
            navigate_fn={fn parent_task -> ~p"/#{@current_user.id}/tasks/#{parent_task}" end}
            patch_fn={
              fn parent_task -> ~p"/#{@current_user.id}/tasks/#{parent_task.id}/new_subtask" end
            }
          />
        </div>
      </div>
    </div>

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
