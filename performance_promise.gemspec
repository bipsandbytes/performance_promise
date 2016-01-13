Gem::Specification.new do |s|
  s.name        = 'performance_promise'
  s.version     = '1.0.0'
  s.date        = '2016-11-11'
  s.summary     = 'Validate your Rails actions\' performance'
  s.description = 'Validate your Rails actions\' performance'
  s.authors     = ['Bipin Suresh']
  s.email       = 'bipins@alumni.stanford.edu'
  s.files       = `git ls-files -z`.split("\x0")
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})
  s.homepage    = 'https://github.com/bipsandbytes/performance_promise'
  s.license     = 'MIT'
end
