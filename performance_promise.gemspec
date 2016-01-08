Gem::Specification.new do |s|
  s.name        = 'performance_promise'
  s.version     = '0.0.1'
  s.date        = '2015-12-14'
  s.summary     = 'Make promises about your actions\' performance'
  s.description = 'Annotate and validate your actions with promises'
  s.authors     = ['Bipin Suresh']
  s.email       = 'bipins@alumni.stanford.edu'
  s.files       = `git ls-files -z`.split("\x0")
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})
  s.homepage    = 'http://rubygems.org/gems/performance_promise'
  s.license     = 'MIT'
end
