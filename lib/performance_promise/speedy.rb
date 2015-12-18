require 'performance_promise.rb'


class Speedy < Performance
  def initialize(klass, method)
    super(klass, method, PerformancePromise.configuration.speedy_promise)
  end
end
