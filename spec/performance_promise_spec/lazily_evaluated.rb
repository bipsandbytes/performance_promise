require 'active_support/time'
require 'logger'
require './lib/performance_promise/performance.rb'


describe 'LazilyEvaluated' do
  it 'creates a lazy-evaluated object a Fixnum' do
    expect(1.query.class).to be LazilyEvaluated
    expect(2.queries.class).to be LazilyEvaluated
  end

  it 'creates a lazy-evaluatd object from ActiveRecord::Base' do
    expect(ActiveRecord::Base.N.queries.class).to be LazilyEvaluated
  end

  it 'creates a new lazy-evaluated object from arithmetic operations' do
    expect((LazilyEvaluated.new(1) + LazilyEvaluated.new(2)).class).to be LazilyEvaluated
    expect((LazilyEvaluated.new(1) - LazilyEvaluated.new(2)).class).to be LazilyEvaluated
    expect((LazilyEvaluated.new(1) * LazilyEvaluated.new(2)).class).to be LazilyEvaluated
    expect((LazilyEvaluated.new(1) / LazilyEvaluated.new(2)).class).to be LazilyEvaluated
  end

  context '#evaluate' do
    before(:all) do
      PerformancePromise.configure do |config|
        config.enable = true
      end
      PerformancePromise.start
    end

    it 'short-circuits in production' do
      expect(Rails).to receive(:env).and_return('production')
      expect(ActiveRecord::Base).not_to receive(:count)
      expect(ActiveRecord::Base.N.queries.evaluate).to be 0
    end

    it 'evaluates Fixnums correctly' do
      expect((1.query).evaluate).to be 1
    end

    it 'lazily evaluates models' do
      expect(ActiveRecord::Base).to receive(:count)
      ActiveRecord::Base.N.evaluate
    end

    it 'evaluates simple arithmetic operations correctly' do
      expect((1.query + 2.queries).evaluate).to be 3
      expect((2.queries - 1.query).evaluate).to be 1
      expect((2.queries * 2.queries).evaluate).to be 4
      expect((2.queries / 2.queries).evaluate).to be 1
    end
  end
end
