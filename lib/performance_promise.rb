require 'performance_promise/decorators'
require 'performance_promise/sql_recorder.rb'
require 'performance_promise/utils.rb'

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
    attr_accessor :logger
    attr_accessor :allowed_environments
    attr_accessor :speedy_promise
    attr_accessor :untagged_methods_are_speedy
    attr_accessor :validate_number_of_queries
    attr_accessor :validate_time_taken_for_render
    attr_accessor :throw_exception

    def initialize
      # Set default values
      @enable = false
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
      @validate_number_of_queries = true
      @validate_time_taken_for_render = true
      @throw_exception = false
    end
  end

  class BrokenPromise < RuntimeError
  end

  @@promises = {}

  def self.promises
    @@promises
  end

  def self.validate_promise(method, db_queries, render_time, options)
    if self.configuration.validate_number_of_queries &&
       options[:makes] &&
       db_queries.length > options[:makes]
      report_promise_failed_too_many_queries(method, db_queries, options[:makes])
    elsif self.configuration.validate_time_taken_for_render &&
          options[:takes] &&
          render_time > options[:takes]
      report_promise_failed_render_took_too_long(method, render_time, options[:takes])
    else
      report_promise_passed(method, db_queries, options)
    end
  end

  def self.report_promise_failed_too_many_queries(method, db_queries, makes)
    guessed_order = Utils.guess_order(db_queries)
    PerformancePromise.configuration.logger.warn '-' * 80
    PerformancePromise.configuration.logger.warn Utils.colored(:red, "Broken promise on #{method}: promised #{makes}, made #{db_queries.length}")
    PerformancePromise.configuration.logger.warn Utils.colored(:cyan, "Possibly #{guessed_order}")
    backtrace = []
    Utils.summarize_queries(db_queries).each do |db_query, count|
      statement = "#{count} x #{db_query[:sql]}"
      PerformancePromise.configuration.logger.warn Utils.colored(:cyan, statement)
      backtrace << statement
      db_query[:trace].each do |trace|
        if trace.starts_with?('app')
          file, line_number = trace.split(':')
          trace = "    |_" + File.read(file).split("\n")[line_number.to_i - 1].strip + ' (' + trace + ')'
        end
        backtrace << trace
        PerformancePromise.configuration.logger.warn Utils.colored(:cyan, trace)
      end
    end
    PerformancePromise.configuration.logger.warn '-' * 80
    if PerformancePromise.configuration.throw_exception
      bp = BrokenPromise.new(
        "Broken promise: Promised #{makes}, Made #{db_queries.length}; "\
        "(Try #{guessed_order})"
      )
      bp.set_backtrace(backtrace)
      raise bp
    end
  end

  def self.report_promise_failed_render_took_too_long(method, render_time, takes)
    PerformancePromise.configuration.logger.warn '-' * 80
    PerformancePromise.configuration.logger.warn Utils.colored(:red, "Broken promise on #{method}: promised #{takes} seconds, took #{render_time} seconds")
    PerformancePromise.configuration.logger.warn '-' * 80
    if PerformancePromise.configuration.throw_exception
      bp = BrokenPromise.new(
        "Broken promise: promised #{takes} seconds, took #{render_time} secondss"
      )
      bp.set_backtrace([])
      raise bp
    end
  end

  def self.report_promise_passed(method, db_queries, options)
    PerformancePromise.configuration.logger.warn '-' * 80
    PerformancePromise.configuration.logger.warn Utils.colored(:green, "Passed promise on #{method}: promised #{options[:makes]}, made #{db_queries.length}")
    PerformancePromise.configuration.logger.warn '-' * 80
  end
end


def n(model)
  return 1 unless PerformancePromise.configuration.allowed_environments.include?(Rails.env)
  model.count
end


class Fixnum
  def queries
    self
  end
  alias :query :queries
end


class Performance < Decorator
  def initialize(klass, method, options)
    @klass, @method = klass, method
    PerformancePromise.promises["#{klass}\##{method.name.to_s}"] = options
  end

  def call(this, *args)
    @method.bind(this).call(*args)
  end
end


class Speedy < Performance
  def initialize(klass, method)
    super(klass, method, PerformancePromise.configuration.speedy_promise)
  end
end
