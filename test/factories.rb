# frozen_string_literal: true

# FactoryBot factories — available in all tests alongside fixtures:
#   create(:user)
#   create(:admin_session, platform_admin: create(:admin_user))
FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password" }
  end

  factory :admin_user do
    email { Faker::Internet.unique.email }
    password { "password" }
    password_confirmation { "password" }
  end

  factory :admin_session do
    association :platform_admin, factory: :admin_user
    token_digest { TokenDigest.digest(SecureRandom.hex(32)) }
    issuing_env { "test" }
    expires_at { 30.days.from_now }
  end

  factory :user_session do
    user
    jti { SecureRandom.uuid }
    issuing_env { "test" }
    expires_at { 30.days.from_now }
  end
end
