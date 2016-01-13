module ValidateFullTableScans
  def validate_full_table_scans(db_queries, render_time, promised)
    full_table_scans = []

    # check the explained queries to see if there were any
    # SCAN TABLEs
    db_queries.each do |db_query|
      detail = db_query[:explained][0]['detail']
      makes_full_table_scan = detail.match(/SCAN TABLE (.*)/)
      if makes_full_table_scan
        table_name = makes_full_table_scan[1]
        full_table_scans << table_name
      end
    end

    # we do not care about duplicates
    full_table_scans = full_table_scans.uniq

    # map the models in the promise to their corresponding table names
    promised_full_table_scans = promised.map { |model| model.table_name }

    # check that the performed FTSs are a subset of the promised FTSs
    passes = (full_table_scans & promised_full_table_scans == full_table_scans)
    error_message = ''
    backtrace = []

    unless passes
        error_message = "Promised table scans on #{promised_full_table_scans}, made: #{full_table_scans}"
    end

    return passes, error_message, backtrace
  end
end
