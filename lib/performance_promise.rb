require 'performance_promise/decorators'
require 'performance_promise/sql_recorder.rb'
require 'performance_promise/utils.rb'
require 'performance_promise/lazily_evaluated.rb'
require 'performance_promise/performance_validations.rb'

module PerformancePromise
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.start
    return unless PerformancePromise.configuration.enable
    return unless PerformancePromise.configuration.allowed_environments.include?(Rails.env)

    ActiveSupport::Notifications.subscribe "sql.active_record" do |name, start, finish, id, payload|
      SQLRecorder.instance.record(payload, finish - start)
    end

    ActiveSupport::Notifications.subscribe "start_processing.action_controller" do |name, start, finish, id, payload|
      SQLRecorder.instance.flush
    end

    ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, start, finish, id, payload|
      db_queries = SQLRecorder.instance.flush
      render_time = finish - start
      method_name = "#{payload[:controller]}\##{payload[:action]}"
      promised = PerformancePromise.promises[method_name]
      if promised
        PerformancePromise::validate_promise(method_name, db_queries, render_time, promised)
      elsif PerformancePromise.configuration.untagged_methods_are_speedy
        PerformancePromise.configuration.logger.warn 'No promises made. Assuming Speedy'
        promised = PerformancePromise.configuration.speedy_promise
        PerformancePromise::validate_promise(method_name, db_queries, render_time, promised)
      end
    end
  end

  class Configuration
    attr_accessor :enable
    attr_accessor :validations
    attr_accessor :logger
    attr_accessor :allowed_environments
    attr_accessor :speedy_promise
    attr_accessor :untagged_methods_are_speedy
    attr_accessor :throw_exception

    def initialize
      # Set default values
      @enable = false
      @validations = [
        :makes,
      ]
      @logger = Rails.logger
      @allowed_environments = [
        'development',
        'test',
      ]
      @untagged_methods_are_speedy = false
      @speedy_promise = {
        :makes => 1.query,
        :takes => 1.second,
      }
      @throw_exception = true
    end
  end

  class BrokenPromise < RuntimeError
  end

  @@promises = {}

  def self.promises
    @@promises
  end

  def self.validate_promise(method, db_queries, render_time, options)
    return if options[:skip]
    promise_broken = false
    self.configuration.validations.each do |validation|
      promised = options[validation]
      if promised
        validation_method = 'validate_' + validation.to_s
        passed, error_message, backtrace =
          PerformanceValidations.send(validation_method, db_queries, render_time, promised)
        unless passed
          if PerformancePromise.configuration.throw_exception
            bp = BrokenPromise.new("Broken promise: #{error_message}")
            bp.set_backtrace(backtrace)
            raise bp
          else
            PerformancePromise.configuration.logger.warn '-' * 80
            PerformancePromise.configuration.logger.warn Utils.colored(:red, error_message)
            backtrace.each do |trace|
              PerformancePromise.configuration.logger.warn Utils.colored(:cyan, error_message)
            end
            PerformancePromise.configuration.logger.warn '-' * 80
          end
          promise_broken = true
        end
      end
    end
    PerformanceValidations.report_promise_passed(method, db_queries, options) unless promise_broken
  end
end
