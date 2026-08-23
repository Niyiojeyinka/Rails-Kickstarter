# frozen_string_literal: true

class ApplicationComponent
  # Value object returned by every component's #call.
  #
  #   result = Users::Creator.call(email: "a@b.c")
  #   result.success? # => true
  #   result.value    # => the created record
  #
  #   result = Users::Creator.call(email: "nope")
  #   result.failure? # => true
  #   result.errors   # => ["Email is invalid"]
  class Result
    attr_reader :value, :errors

    def self.success(value = nil)
      new(ok: true, value: value)
    end

    def self.failure(errors)
      new(ok: false, errors: errors)
    end

    def initialize(ok:, value: nil, errors: [])
      @ok = ok
      @value = value
      @errors = normalize_errors(errors)
    end

    def success?
      @ok
    end

    def failure?
      !@ok
    end

    # First error message, for single-error fast paths.
    def error
      errors.first
    end

    private

    def normalize_errors(errors)
      return errors.full_messages if errors.respond_to?(:full_messages)

      Array(errors).flatten
    end
  end
end
