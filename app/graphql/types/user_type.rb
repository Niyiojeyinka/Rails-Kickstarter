# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    description "A registered user"

    field :id, ID, null: false
    field :email, String, null: false
  end
end
