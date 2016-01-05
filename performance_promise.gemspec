Gem::Specification.new do |s|
  s.name        = 'performance_promise'
  s.version     = '0.0.1'
  s.date        = '2015-12-14'
  s.summary     = 'Make promises about your actions\' performance'
  s.description = 'Annotate and validate your actions with promises'
  s.authors     = ['Bipin Suresh']
  s.email       = 'bipins@alumni.stanford.edu'
  s.files       = [
    'lib/performance_promise.rb',
    'lib/performance_promise/decorators.rb',
    'lib/performance_promise/sql_recorder.rb',
    'lib/performance_promise/performance.rb',
    'lib/performance_promise/speedy.rb',
    'lib/performance_promise/utils.rb',
    'lib/performance_promise/lazily_evaluated.rb',
    'lib/performance_promise/performance_validations.rb',
    'lib/performance_promise/validations/number_of_db_queries.rb',
    'lib/performance_promise/validations/time_taken_for_render.rb',
  ]
  s.homepage    = 'http://rubygems.org/gems/performance_promise'
  s.license     = 'MIT'
end
