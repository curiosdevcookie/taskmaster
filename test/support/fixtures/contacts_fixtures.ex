defmodule TaskMaster.ContactsFixtures do
  import TaskMaster.OrganizationsFixtures

  def contact_fixture(attrs \\ %{}) do
    organization = organization_fixture()

    attrs =
      Enum.into(attrs, %{
        first_name: "John",
        last_name: "Doe",
        company: "ACME Corp",
        area_of_expertise: "Software Development",
        email: "john@example.com",
        phone: "123-456-7890",
        mobile: "987-654-3210",
        street: "Main St",
        street_number: "123",
        postal_code: "12345",
        city: "Anytown",
        notes: "Some notes",
        organization_id: organization.id
      })

    IO.inspect(attrs, label: "Attrs in fixture")

    {:ok, contact} = TaskMaster.Contacts.create_contact(attrs)
    IO.inspect(contact, label: "Created contact")

    contact
  end
end
