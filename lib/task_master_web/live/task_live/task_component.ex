defmodule TaskMasterWeb.TaskLive.TaskComponent do
  use TaskMasterWeb, :live_component

  alias TaskMaster.Tasks
  alias TaskMaster.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= gettext("Use this form to manage task records in your database.") %>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="task-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <input type="hidden" name="task[created_by]" value={@current_user.id} />
        <input type="hidden" name="task[organization_id]" value={@current_user.organization_id} />
        <.input field={@form[:title]} type="text" label={gettext("Title")} />
        <.input field={@form[:description]} type="text" label={gettext("Description")} />
        <.input field={@form[:due_date]} type="date" label={gettext("Due date")} />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          prompt={gettext("Choose a value")}
          options={
            TaskMasterWeb.Helpers.EnumTranslator.translate_enum(TaskMaster.Tasks.Task, :status)
          }
        />
        <.input field={@form[:duration]} type="number" label={gettext("Duration")} />
        <.input
          field={@form[:priority]}
          type="select"
          label={gettext("Priority")}
          prompt={gettext("Choose a value")}
          options={
            TaskMasterWeb.Helpers.EnumTranslator.translate_enum(TaskMaster.Tasks.Task, :priority)
          }
        />
        <.input field={@form[:indoor]} type="checkbox" label={gettext("Indoor")} />

        <div class="mb-4">
          <div class="mt-2 flex flex-wrap gap-2">
            <%= for participant <- Enum.sort(@participants) do %>
              <div class="flex items-center bg-blue-100 rounded-full px-3 py-1">
                <span class="text-sm text-blue-800">
                  <%= participant.first_name %> <%= participant.last_name %>
                </span>
                <button
                  type="button"
                  phx-click="remove_participant"
                  phx-value-id={participant.id}
                  phx-target={@myself}
                  class="ml-2 text-blue-600 hover:text-blue-800"
                >
                  &times;
                </button>
              </div>
            <% end %>
          </div>
        </div>

        <div class="flex gap-4">
          <.input
            type="select"
            id="participant-select"
            name="participant"
            label={gettext("Who is participating?")}
            prompt={gettext("Select")}
            options={
              Enum.map(@available_users, fn user ->
                {user.first_name <> " " <> user.last_name, user.id}
              end)
            }
            value={@selected_participant_id}
            phx-change="add_participant"
            phx-target={@myself}
          />
        </div>

        <:actions>
          <.button phx-disable-with="Saving..."><%= gettext("Save") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{task: task} = assigns, socket) do
    changeset = Tasks.change_task(task)
    participants = Tasks.list_task_participants(task.id)
    org_id = assigns.current_user.organization_id
    all_users = Accounts.list_users(org_id)
    available_users = Enum.filter(all_users, fn user -> not Enum.member?(participants, user) end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:participants, participants)
     |> assign(:available_users, available_users)
     |> assign(:selected_participant_id, nil)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    changeset =
      socket.assigns.task
      |> Tasks.change_task(task_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"task" => task_params}, socket) do
    save_task(socket, socket.assigns.action, task_params)
  end

  @impl true
  def handle_event("add_participant", %{"participant" => user_id}, socket) do
    case Accounts.get_user!(user_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Selected user not found")}

      user ->
        updated_participants = [user | socket.assigns.participants] |> Enum.uniq_by(& &1.id)

        {:noreply,
         socket
         |> assign(:participants, updated_participants)
         |> assign(:selected_participant_id, nil)
         |> put_flash(:info, "Participant added successfully")}
    end
  end

  @impl true
  def handle_event("remove_participant", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    updated_participants =
      Enum.filter(socket.assigns.participants, fn participant -> participant.id != user.id end)

    updated_available_users =
      [user | socket.assigns.available_users]
      |> Enum.uniq_by(& &1.id)

    {:noreply,
     socket
     |> assign(:participants, updated_participants)
     |> assign(:available_users, updated_available_users)}
  end

  # defp update_task_changeset(socket) do
  #   changeset =
  #     socket.assigns.task
  #     |> Tasks.change_task()

  #   assign(socket, :form, to_form(changeset))
  # end

  defp save_task(socket, :edit, task_params) do
    org_id = socket.assigns.current_user.organization_id |> dbg()

    case Tasks.update_task(socket.assigns.task, task_params, socket.assigns.participants, org_id) do
      {:ok, task} ->
        notify_parent({:saved, task})

        {:noreply,
         socket
         |> assign(:task, task)
         |> put_flash(:info, gettext("Task updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_task(socket, :new, task_params) do
    org_id = socket.assigns.current_user.organization_id |> dbg()

    case Tasks.create_task(task_params, socket.assigns.participants, org_id) do
      {:ok, task} ->
        notify_parent({:saved, task})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Task created successfully"))
         |> push_navigate(to: ~p"/#{socket.assigns.current_user.id}/tasks")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
