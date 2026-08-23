# frozen_string_literal: true

require "test_helper"

class TokenDigestTest < ActiveSupport::TestCase
  test "generate returns URL-safe tokens" do
    token = TokenDigest.generate(16)

    assert_kind_of String, token
    assert_match(/\A[A-Za-z0-9_=-]+\z/, token)
    assert_operator token.length, :>, 16
  end

  test "digest returns a stable SHA-256 hex digest" do
    assert_equal TokenDigest.digest("secret"), TokenDigest.digest("secret")
    assert_equal 64, TokenDigest.digest("secret").length
    assert_not_equal TokenDigest.digest("secret"), TokenDigest.digest("other")
  end

  test "truncate_ua keeps a prefix of long user agents" do
    assert_equal "Mozilla", TokenDigest.truncate_ua("Mozilla", limit: 7)
    assert_equal "Mozilla/5.0", TokenDigest.truncate_ua("Mozilla/5.0", limit: 255)
    assert_equal "", TokenDigest.truncate_ua(nil)
  end
end
