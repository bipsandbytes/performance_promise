require 'performance_promise.rb'


class Performance < Decorator
  def initialize(klass, method, options)
    @klass, @method = klass, method
    PerformancePromise.promises["#{klass}\##{method.name.to_s}"] = options
  end

  def call(this, *args)
    @method.bind(this).call(*args)
  end
end
