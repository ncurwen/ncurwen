ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "minitest/error_on_warning"
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new(color: true)

# Scope minitest/error_on_warning to warnings originating from our own code.
# Warnings from gems (e.g. Devise emitting Rack deprecation notices) get printed
# through the default Warning.warn instead of failing tests.
module Minitest
  module ErrorOnWarning
    APP_ROOT = Rails.root.to_s.freeze
    GEM_ROOT = Bundler.bundle_path.to_s.freeze

    def warn(message, category: nil)
      from_app = caller_locations(1, 30).any? do |loc|
        loc.path.start_with?(APP_ROOT) && !loc.path.start_with?(GEM_ROOT)
      end

      if from_app
        message = "[#{category}] #{message}" if category
        raise UnexpectedWarning, message
      else
        super
      end
    end
  end
end

Rails.application.routes.default_url_options[:host] = "www.example.com"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
