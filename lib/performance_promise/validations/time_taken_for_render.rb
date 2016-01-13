module ValidateTimeTakenForRender
  def validate_takes(db_queries, render_time, takes)
    passes = (render_time <= takes)
    error_message = ''
    backtrace = []

    unless passes
        error_message = "promised #{takes} seconds, took #{render_time} seconds"
    end

    return passes, error_message, backtrace
  end
end
