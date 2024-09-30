defmodule TaskMasterWeb.ContactLive.ContactComponent do
  use TaskMasterWeb, :live_component

  alias TaskMaster.Contacts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="contact-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:first_name]} type="text" label={gettext("First name")} />
        <.input field={@form[:last_name]} type="text" label={gettext("Last name")} />
        <.input field={@form[:company]} type="text" label={gettext("Company")} />
        <.input field={@form[:area_of_expertise]} type="text" label={gettext("Area of expertise")} />
        <.input field={@form[:email]} type="email" label={gettext("Email")} />
        <.input field={@form[:phone]} type="tel" label={gettext("Phone")} />
        <.input field={@form[:mobile]} type="tel" label={gettext("Mobile")} />
        <.input field={@form[:street]} type="text" label={gettext("Street")} />
        <.input field={@form[:street_number]} type="text" label={gettext("Street number")} />
        <.input field={@form[:postal_code]} type="text" label={gettext("Postal code")} />
        <.input field={@form[:city]} type="text" label={gettext("City")} />
        <.input field={@form[:notes]} type="text" label={gettext("Notes")} />

        <:actions>
          <div class="flex justify-end w-full">
            <.button class="btn-primary" phx-disable-with="Saving...">
              <%= gettext("Save") %>
            </.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{contact: contact} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Contacts.change_contact(contact))
     end)}
  end

  @impl true
  def handle_event("validate", %{"contact" => contact_params}, socket) do
    changeset = Contacts.change_contact(socket.assigns.contact, contact_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"contact" => contact_params}, socket) do
    save_contact(socket, socket.assigns.action, contact_params)
  end

  defp save_contact(socket, :edit, contact_params) do
    contact_params =
      Map.put(contact_params, "organization_id", socket.assigns.current_user.organization_id)

    case Contacts.update_contact(socket.assigns.contact, contact_params) do
      {:ok, contact} ->
        notify_parent({:saved, contact})

        {:noreply,
         socket
         |> put_flash(:info, "Contact updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_contact(socket, :new, contact_params) do
    contact_params =
      Map.put(contact_params, "organization_id", socket.assigns.current_user.organization_id)

    case Contacts.create_contact(contact_params) do
      {:ok, contact} ->
        notify_parent({:saved, contact})

        {:noreply,
         socket
         |> put_flash(:info, "Contact created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
