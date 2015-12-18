require './lib/performance_promise/speedy.rb'


describe 'Speedy' do
  it 'promises speedy configuration when tagged with Speedy()' do
    class ArticleController
      Speedy()
      def index
      end
    end
    speedy_promise = PerformancePromise.configuration.speedy_promise
    expect(PerformancePromise.promises['ArticleController#index']).to equal(speedy_promise)
  end
end
