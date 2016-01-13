Gem::Specification.new do |s|
  s.name        = 'performance_promise'
  s.version     = '0.0.1'
  s.date        = '2015-12-14'
  s.summary     = 'Validate your Rails actions\' performance'
  s.description = 'Validate your Rails actions\' performance'
  s.authors     = ['Bipin Suresh']
  s.email       = 'bipins@alumni.stanford.edu'
  s.files       = `git ls-files -z`.split("\x0")
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})
  s.homepage    = 'http://rubygems.org/gems/performance_promise'
  s.license     = 'MIT'
end
