require 'performance_promise.rb'


class LazilyEvaluated
  def initialize(c)
    if c.is_a?(Fixnum)
      @operand1 = c
      @operator = 'constant'
    elsif c.is_a?(Class)
      @operand1 = c
      @operator = 'model'
    elsif c.is_a?(Array)
      @operand1, @operand2, @operator = c
    else
      raise
    end
  end

  def +(other)
    return LazilyEvaluated.new([self, other, '+'])
  end

  def -(other)
    return LazilyEvaluated.new([self, other, '-'])
  end

  def *(other)
    return LazilyEvaluated.new([self, other, '*'])
  end

  def /(other)
    return LazilyEvaluated.new([self, other, '/'])
  end

  def evaluate
    # don't do anything in prod-like environments
    return 0 unless PerformancePromise.configuration.allowed_environments.include?(Rails.env)

    case @operator
    when 'constant'
      return @operand1
    when 'model'
      return @operand1.count
    when '+'
      return @operand1.evaluate + @operand2.evaluate
    when '-'
      return @operand1.evaluate - @operand2.evaluate
    when '*'
      return @operand1.evaluate * @operand2.evaluate
    when '/'
      return @operand1.evaluate / @operand2.evaluate
    else
      raise
    end
  end

  def queries
    # syntactic sugar
    self
  end
end


class Fixnum
  def queries
    LazilyEvaluated.new(self)
  end
  alias query queries
end


module ActiveRecord
  class Base
    def self.N
      LazilyEvaluated.new(self)
    end
  end
end
