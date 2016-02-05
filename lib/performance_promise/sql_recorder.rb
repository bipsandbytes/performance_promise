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

    # do not record/analyze explain queries used in dev
    return if payload[:sql].include?('EXPLAIN')

    sql = payload[:sql]
    cleaned_trace = clean_trace(caller)
    if sql.include?('SELECT')
      connection = ActiveRecord::Base.connection
      adapter_name = connection.adapter_name
      if adapter_name == 'Mysql2'
        explained = connection.explain(connection, sql).as_json
      elsif adapter_name == 'SQLite'
        explained = connection.execute("EXPLAIN QUERY PLAN #{sql}", 'SQLR-EXPLAIN')
      elsif
        PerformancePromise.configuration.logger.warn("Unkown database adapter {adapter_name}")
        explained = connection.execute("EXPLAIN QUERY PLAN #{sql}", 'SQLR-EXPLAIN')
      end
    else
      explained = nil
    end

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
    payload[:name] && ignore_query_names.any? { |name| payload[:name].include?(name) }
  end

  def clean_trace(trace)
    Rails.backtrace_cleaner.remove_silencers!
    Rails.backtrace_cleaner.add_silencer { |line| not line =~ /^(app)\// }
    Rails.backtrace_cleaner.clean(trace)
  end
end
SQLRecorder.instance.flush
