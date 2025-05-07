class LoggingController < ApplicationController
  def append_info_to_payload(payload)
    super

    # HTTP_TRACEPARENTヘッダーから trace_id を抽出
    if request.headers["HTTP_TRACEPARENT"].present?
      # W3C Trace Context 形式（00-trace_id-parent_id-flags）からtrace_idを抽出
      trace_parent = request.headers["HTTP_TRACEPARENT"]
      if trace_parent =~ /^00-([0-9a-f]{32})-/
        payload[:trace_id] = $1
      end
    end
  end

  def test
    logger.error "Custom Error test"
  end
end
