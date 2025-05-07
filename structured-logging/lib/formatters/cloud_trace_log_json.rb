require "json"
require "semantic_logger"

module Formatters
  class CloudTraceLogJson < SemanticLogger::Formatters::Raw
    # Default JSON time format is ISO8601
    def initialize(time_format: :iso_8601, time_key: :timestamp, **args)
      super(time_format: time_format, time_key: time_key, **args)
    end

    def traceparent
      if log.named_tags && log.named_tags[:traceparent]
        hash[:traceparent] = log.named_tags[:traceparent]
      end
    end

    def trace
      if log.named_tags && log.named_tags[:trace_id]
        trace_id = log.named_tags[:trace_id]
      elsif log.named_tags && log.named_tags[:request_id]
        trace_id = log.named_tags[:request_id].gsub("-", "")
      else
        return
      end
      hash["logging.googleapis.com/trace"] = "projects/#{ENV["PROJECT_ID"]}/traces/#{trace_id}" if trace_id && ! ENV["PROJECT_ID"].nil? && ! ENV["PROJECT_ID"].empty?
    end

    # Returns log messages in Hash format
    def call(log, logger)
      self.hash   = {}
      self.log    = log
      self.logger = logger

      host
      application
      environment
      time
      level
      pid
      thread_name
      file_name_and_line
      duration
      tags
      named_tags
      name
      message
      payload
      exception
      metric
      traceparent
      trace

      hash.to_json
    end
  end
end
