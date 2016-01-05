module ValidateTimeTakenForRender
  def validate_takes(db_queries, render_time, takes)
    render_time > takes
  end

  def report_failed_takes(db_queries, render_time, takes)
    error_message = "promised #{takes} seconds, took #{render_time} seconds"
    backtrace = []
    return error_message, backtrace
  end
end
