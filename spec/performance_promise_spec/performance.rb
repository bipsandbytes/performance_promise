require './lib/performance_promise/performance.rb'


describe 'Performance' do
  before(:all) do
    class ArticleController
      extend MethodDecorators
    end
  end

  it 'does not registers a promise when a function is not decorated' do
    expect(PerformancePromise.promises['ArticleController#index']).to be_falsey
  end

  it 'registers a promise when a function is decorated' do
    a = ArticleController.new
    class ArticleController
      Performance :makes => 1.query
      def index
      end
    end
    expect(PerformancePromise.promises['ArticleController#index']).to be_truthy
  end

  it 'calls the decorated function when called' do
    a = ArticleController.new
    expect(PerformancePromise.promises['ArticleController#index']).to be_truthy
    expect(a).to receive(:index).with('argument')
    a.index('argument')
  end
end
