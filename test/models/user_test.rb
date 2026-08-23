# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
class UserTest < ActiveSupport::TestCase
  test "requires a valid, unique email and a password" do
    user = User.new(email: "nope", password: "s3cret")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"

    user = User.new(email: users(:one).email, password: "s3cret")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"

    assert_predicate User.new(email: "ok@example.com", password: "s3cret"), :valid?
  end

  test "normalizes email to lowercase" do
    user = User.create!(email: "MixedCase@Example.com", password: "s3cret")

    assert_equal "mixedcase@example.com", user.email
  end

  test "authenticates with the password" do
    assert users(:one).authenticate("password")
    assert_not users(:one).authenticate("wrong")
  end

  test "destroys its sessions with it" do
    user = users(:one)
    UserSessions::Creator.call(user: user)

    assert_difference -> { UserSession.count } => -1 do
      user.destroy
    end
  end
end
