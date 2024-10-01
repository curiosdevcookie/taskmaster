defmodule TaskMaster.ContactsTest do
  use TaskMaster.DataCase

  alias TaskMaster.Contacts
  alias TaskMaster.Contacts.Contact
  import TaskMaster.ContactsFixtures
  import TaskMaster.OrganizationsFixtures

  describe "contacts" do
    setup do
      organization = organization_fixture()
      %{organization: organization}
    end

    test "list_contacts/1 returns all contacts for an organization", %{organization: organization} do
      contact1 = contact_fixture(%{organization_id: organization.id})
      contact2 = contact_fixture(%{organization_id: organization.id})
      assert Contacts.list_contacts(organization.id) == [contact1, contact2]
    end

    test "get_contact!/1 returns the contact with given id" do
      contact = contact_fixture()
      assert Contacts.get_contact!(contact.id) == contact
    end

    test "create_contact/1 with valid data creates a contact" do
      organization = organization_fixture()

      valid_attrs = %{
        first_name: "Jane",
        last_name: "Smith",
        company: "Tech Corp",
        area_of_expertise: "Data Science",
        email: "jane@example.com",
        phone: "555-123-4567",
        mobile: "555-987-6543",
        street: "Oak St",
        street_number: "456",
        postal_code: "67890",
        city: "Tech City",
        notes: "Brilliant data scientist",
        organization_id: organization.id
      }

      assert {:ok, %Contact{} = contact} = Contacts.create_contact(valid_attrs)
      assert contact.first_name == "Jane"
      assert contact.last_name == "Smith"
      assert contact.company == "Tech Corp"
      assert contact.area_of_expertise == "Data Science"
      assert contact.email == "jane@example.com"
      assert contact.organization_id == organization.id
    end

    test "create_contact/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contacts.create_contact(%{})
    end

    test "update_contact/2 with valid data updates the contact" do
      contact = contact_fixture()

      update_attrs = %{
        first_name: "Updated First Name",
        last_name: "Updated Last Name",
        company: "Updated Company",
        area_of_expertise: "Updated Expertise"
      }

      assert {:ok, %Contact{} = updated_contact} = Contacts.update_contact(contact, update_attrs)
      assert updated_contact.first_name == "Updated First Name"
      assert updated_contact.last_name == "Updated Last Name"
      assert updated_contact.company == "Updated Company"
      assert updated_contact.area_of_expertise == "Updated Expertise"
    end

    test "update_contact/2 with invalid data returns error changeset" do
      contact = contact_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Contacts.update_contact(contact, %{company: nil, area_of_expertise: nil})

      assert contact == Contacts.get_contact!(contact.id)
    end

    test "delete_contact/1 deletes the contact" do
      contact = contact_fixture()
      assert {:ok, %Contact{}} = Contacts.delete_contact(contact)
      assert_raise Ecto.NoResultsError, fn -> Contacts.get_contact!(contact.id) end
    end

    test "change_contact/1 returns a contact changeset" do
      contact = contact_fixture()
      assert %Ecto.Changeset{} = Contacts.change_contact(contact)
    end

    test "create_contact/1 with missing required fields returns error changeset" do
      organization = organization_fixture()
      invalid_attrs = %{organization_id: organization.id}
      assert {:error, %Ecto.Changeset{}} = Contacts.create_contact(invalid_attrs)
    end

    test "list_contacts/1 returns an empty list when no contacts exist for an organization" do
      organization = organization_fixture()
      assert Contacts.list_contacts(organization.id) == []
    end
  end
end
