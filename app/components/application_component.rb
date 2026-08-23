# frozen_string_literal: true

# Base class for all internal business-logic components.
#
# Components are single-purpose, verb-named classes grouped by domain,
# following the Creator / Updater / Deleter pattern:
#
#   Users::Creator.call(email: "a@b.c")   # => ApplicationComponent::Result
#   Users::Updater.call(user, name: "X")
#   Users::Deleter.call(user)
#
# Conventions:
#   - Name the file after the domain folder: app/components/users/creator.rb
#     defines Users::Creator.
#   - Each component implements #call and returns an ApplicationComponent::Result.
#   - Wrap multi-step writes in a transaction and rescue inside #call; components
#     never raise for expected failures — they return failure results.
#   - Inside a namespaced component, refer to top-level models with :: to avoid
#     lexical constant lookup surprises (e.g. ::User, not User, inside Users::Creator).
class ApplicationComponent
  # Entry point: instantiates with the given arguments and invokes #call.
  def self.call(...)
    new(...).call
  end

  # Subclasses override this with the actual business logic.
  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  def success(value = nil)
    ApplicationComponent::Result.success(value)
  end

  def failure(errors)
    ApplicationComponent::Result.failure(errors)
  end
end
