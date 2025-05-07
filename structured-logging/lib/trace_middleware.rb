class TraceMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # HTTP_TRACEPARENTヘッダーを抽出
    trace_parent = extract_trace_parent(env)
    if trace_parent
      env[:traceparent] = trace_parent
    end

    # ヘッダーからtrace_idを抽出、
    # ない場合はSecureRandom.uuidを使用
    env[:trace_id] = make_trace_id(trace_parent)

    @app.call(env)
  end

  private

  def extract_trace_parent(env)
    if env["HTTP_TRACEPARENT"] && !env["HTTP_TRACEPARENT"].empty?
      env["HTTP_TRACEPARENT"]
    end
  end

  def make_trace_id(trace_parent)
    if trace_parent.present? && trace_parent =~ /^00-([0-9a-f]{32})-/
      return $1
    end
    internal_trace_id
  end

  def internal_trace_id
    SecureRandom.uuid.gsub("-", "")
  end
end
