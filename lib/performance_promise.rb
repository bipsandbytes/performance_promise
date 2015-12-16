require 'performance_promise/decorators'
require 'performance_promise/sql_recorder.rb'

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
      method_name = "#{payload[:controller]}\##{payload[:action]}"
      promised = PerformancePromise.promises[method_name]
      if promised
        PerformancePromise::validate_promise(method_name, db_queries, promised)
      elsif PerformancePromise.configuration.untagged_methods_are_speedy
        PerformancePromise.configuration.logger.warn 'No promises made. Assuming Speedy'
        promised = PerformancePromise.configuration.speedy_promise[:max_queries]
        PerformancePromise::validate_promise(method_name, db_queries, promised)
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
        :max_queries => 1,
      }
      @validate_number_of_queries = true
      @throw_exception = false
    end
  end

  class BrokenPromise < RuntimeError
  end

  @@promises = {}

  def self.promises
    @@promises
  end

  def self.validate_promise(method, db_queries, max_queries)
    if self.configuration.validate_number_of_queries && db_queries.length > max_queries
      report_promise_failed_too_many_queries(method, db_queries, max_queries)
    else
      report_promise_passed(method, db_queries, max_queries)
    end
  end

  def self.report_promise_failed_too_many_queries(method, db_queries, max_queries)
    guessed_order = guess_order(db_queries)
    PerformancePromise.configuration.logger.warn '-' * 80
    PerformancePromise.configuration.logger.warn colored(:red, "Broken promise on #{method}: promised #{max_queries}, made #{db_queries.length}")
    PerformancePromise.configuration.logger.warn colored(:cyan, "Possibly #{guessed_order}")
    backtrace = []
    summarize_queries(db_queries).each do |db_query, count|
      statement = "#{count} x #{db_query[:sql]}"
      PerformancePromise.configuration.logger.warn colored(:cyan, statement)
      backtrace << statement
      db_query[:trace].each do |trace|
        if trace.starts_with?('app')
          file, line_number = trace.split(':')
          trace = "    |_" + File.read(file).split("\n")[line_number.to_i - 1].strip + ' (' + trace + ')'
        end
        backtrace << trace
        PerformancePromise.configuration.logger.warn colored(:cyan, trace)
      end
    end
    PerformancePromise.configuration.logger.warn '-' * 80
    if PerformancePromise.configuration.throw_exception
      bp = BrokenPromise.new(
        "Broken promise: Promised #{max_queries}, Made #{db_queries.length}; "\
        "(Try #{guessed_order})"
      )
      bp.set_backtrace(backtrace)
      raise bp
    end
  end

  def self.report_promise_passed(method, db_queries, max_queries)
    PerformancePromise.configuration.logger.warn '-' * 80
    PerformancePromise.configuration.logger.warn colored(:green, "Passed promise on #{method}: promised #{max_queries}, made #{db_queries.length}")
    PerformancePromise.configuration.logger.warn '-' * 80
  end

  def self.summarize_queries(db_queries)
    summary = Hash.new(0)
    db_queries.each do |query|
      summary[query.except(:duration)] += 1
    end
    summary
  end

  def self.guess_order(db_queries)
    order = []
    queries_with_count = summarize_queries(db_queries)
    queries_with_count.each do |query, count|
      if count == 1
        order << "1.queries"
      else
        puts query[:sql]
        if (lookup_field = /WHERE .*"(.*?_id)" = \?/.match(query[:sql]))
          klass = lookup_field[1].humanize
          order << "#{klass}.count.queries"
        else
          order << "n(???)"
        end
      end
    end

    order.join(" + ")
  end

  def self.colored(color, string)
    color =
      case color
      when :red
        "\e[31m"
      when :green
        "\e[32m"
      when :cyan
        "\e[36m"
      end
    end_color = "\e[0m"
    "#{color}#{string}#{end_color}"
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
  def initialize(klass, method, max_queries)
    @klass, @method = klass, method
    PerformancePromise.promises["#{klass}\##{method.name.to_s}"] = max_queries
  end

  def call(this, *args)
    @method.bind(this).call(*args)
  end
end


class Speedy < Performance
  def initialize(klass, method)
    super(klass, method, PerformancePromise.configuration.speedy_promise[:max_queries])
  end
end
