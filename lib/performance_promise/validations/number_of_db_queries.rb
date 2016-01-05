module ValidateNumberOfQueries
  def validate_makes(db_queries, render_time, makes)
    db_queries.length > makes.evaluate
  end

  def report_failed_makes(db_queries, render_time, makes)
    makes = makes.evaluate
    guessed_order = Utils.guess_order(db_queries)
    error_message = "promised #{makes}, made #{db_queries.length} (possibly #{guessed_order})"
    backtrace = []
    Utils.summarize_queries(db_queries).each do |db_query, count|
      statement = "#{count} x #{db_query[:sql]}"
      backtrace << statement
      db_query[:trace].each do |trace|
        if trace.starts_with?('app')
          file, line_number = trace.split(':')
          trace = "    |_" + File.read(file).split("\n")[line_number.to_i - 1].strip + ' (' + trace + ')'
        end
        backtrace << trace
      end
    end
    return error_message, backtrace
  end
end
