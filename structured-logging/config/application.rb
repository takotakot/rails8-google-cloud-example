require_relative "boot"

require "rails/all"
require_relative "../lib/trace_middleware"
require_relative "../lib/formatters/cloud_trace_log_json"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module StructuredLogging
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Extract traceparent and set `env[:traceparent]` and `env[:trace_id]`.
    # config.middleware.insert_after 0, TraceMiddleware
    config.middleware.insert_after ActionDispatch::RequestId, TraceMiddleware

    config.rails_semantic_logger.started = true
    config.rails_semantic_logger.add_file_appender = false
    # config.semantic_logger.add_appender(io: $stdout, formatter: :json)
    config.semantic_logger.add_appender(io: $stdout, formatter: Formatters::CloudTraceLogJson.new)

    # トレースIDをログタグとして追加
    # production.rb では独自定義されているので注意
    config.log_tags = {
      request_id: :request_id,
      trace_id: ->(request) { request.env[:trace_id] },
      traceparent: ->(request) { request.env[:traceparent] }
      # project_id: ->(request) { Google::Cloud::Trace.project_id if defined? Google::Cloud::Trace.project_id },
    }

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
