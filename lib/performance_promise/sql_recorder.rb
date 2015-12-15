require 'singleton'


class SQLRecorder
  include Singleton

  @db_queries = []
  def flush
    captured_queries = @db_queries
    @db_queries = []
    return captured_queries
  end

  def record(payload, duration)
    return if invalid_payload?(payload)
    sql = payload[:sql]
    cleaned_trace = clean_trace(caller)
    explained = ActiveRecord::Base.connection.execute("EXPLAIN QUERY PLAN #{sql}", 'SQLR-EXPLAIN')
    @db_queries << {
      :sql => sql,
      :duration => duration,
      :trace => cleaned_trace,
      :explained => explained,
    }
  end

  def invalid_payload?(payload)
    ignore_query_names = [
      'SCHEMA',
      'SQLR-EXPLAIN',
    ]
    payload[:name] && ignore_query_names.any? { |name| payload[:name].in?(name) }
  end

  def clean_trace(trace)
    Rails.backtrace_cleaner.remove_silencers!
    Rails.backtrace_cleaner.add_silencer { |line| not line =~ /^(app)\// }
    Rails.backtrace_cleaner.clean(trace)
  end
end
SQLRecorder.instance.flush
