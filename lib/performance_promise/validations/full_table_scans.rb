module ValidateFullTableScans
  def validate_full_table_scans(db_queries, render_time, promised)
    full_table_scans = []
    backtrace = []

    # check the explained queries to see if there were any
    # SCAN TABLEs
    db_queries.each do |db_query|
      if db_query[:explained]
        join_type = db_query[:explained].first[3]
        if join_type

          adapter_name = ActiveRecord::Base.connection.adapter_name
          if adapter_name == 'Mysql2'
            makes_full_table_scan = join_type.match(/ALL/)
            table_name = db_query[:explained][0][2]
          elsif adapter_name == 'SQLite'
            makes_full_table_scan = join_type.match(/SCAN TABLE (.*)/)
            table_name = makes_full_table_scan[1]
          else
            PerformancePromise.configuration.logger.warn("Unkown database adapter {adapter_name}")
            makes_full_table_scan = join_type.match(/SCAN TABLE (.*)/)
            table_name = makes_full_table_scan[1]
          end

          if makes_full_table_scan
            full_table_scans << table_name

            backtrace << db_query[:sql]
            db_query[:trace].each do |trace|
              if trace.starts_with?('app')
                file, line_number = trace.split(':')
                trace = '    |_' +
                  File.read(file).split("\n")[line_number.to_i - 1].strip +
                  ' (' + trace + ')'
              end
              backtrace << trace
            end

          end
        end
      end
    end

    # we do not care about duplicates
    full_table_scans = full_table_scans.uniq

    # map the models in the promise to their corresponding table names
    promised_full_table_scans = promised.map { |model| model.table_name }

    # check that the performed FTSs are a subset of the promised FTSs
    passes = (full_table_scans & promised_full_table_scans == full_table_scans)
    error_message = ''

    unless passes
        error_message = "Promised table scans on #{promised_full_table_scans}, made: #{full_table_scans}"
    end

    return passes, error_message, backtrace
  end
end
