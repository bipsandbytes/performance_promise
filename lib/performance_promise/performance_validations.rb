require 'performance_promise/validations/number_of_db_queries.rb'
require 'performance_promise/validations/time_taken_for_render.rb'


module PerformanceValidations
  extend ValidateNumberOfQueries
  extend ValidateTimeTakenForRender

  def self.report_promise_passed(method, db_queries, options)
    PerformancePromise.configuration.logger.warn '-' * 80
    PerformancePromise.configuration.logger.warn Utils.colored(:green, "Passed promise on #{method}")
    PerformancePromise.configuration.logger.warn '-' * 80
  end
end
