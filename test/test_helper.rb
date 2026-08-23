ENV["RAILS_ENV"] ||= "test"

# ---- Coverage (must start BEFORE the application code loads) ----
if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-cobertura"

  SimpleCov.start "rails" do
    # Keep reports CI-ready and enforce a floor; raise it as tests grow.
    minimum_coverage 85

    add_group "Components", "app/components"
    add_group "GraphQL", "app/graphql"
    add_group "API", "app/controllers/api"
    add_group "Lib", "lib"

    # Generated DSL/boilerplate — excluded from the coverage floor:
    add_filter "app/admin"                        # ActiveAdmin resource DSL
    add_filter "config"                           # boot-time configuration
    add_filter "app/graphql/types/base_"          # GraphQL base classes
    add_filter "app/graphql/mutations/base_mutation.rb"
    add_filter "app/graphql/resolvers/base_resolver.rb"
    add_filter "app/channels/application_cable"
    add_filter "app/jobs/application_job.rb"
    add_filter "app/mailers/application_mailer.rb"
    add_filter "app/controllers/application_controller.rb"
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ])
end

require_relative "../config/environment"
require "rails/test_help"

# ---- Nicer test output ----
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# ---- Mocks on any object (Mocha.expects / .stubs) ----
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Run a block with temporary ENV overrides, restoring the original values
    # (or removing keys that were unset) afterwards.
    def with_env(overrides)
      originals = overrides.keys.index_with { |key| ENV[key] }
      overrides.each { |key, value| ENV[key] = value }
      yield
    ensure
      originals.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end
  end
end
