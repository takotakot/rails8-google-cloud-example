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

    # Overwrite the request_id with the trace_id
    req = ActionDispatch::Request.new env
    req.request_id = insert_hyphens(env[:trace_id])

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

  def insert_hyphens(trace_id)
    trace_id = trace_id.dup.to_s

    # 各位置にハイフンを挿入（文字列長をチェックしながら）
    [ 8, 13, 18, 23 ].each do |pos|
      break if trace_id.length <= pos
      trace_id.insert(pos, "-")
    end

    trace_id
  end
end
