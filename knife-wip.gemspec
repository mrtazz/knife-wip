$:.push File.expand_path('../lib', __FILE__)
require 'knife-wip'

Gem::Specification.new do |gem|
  gem.name          = 'knife-wip'
  gem.version       = KnifeWip::VERSION
  gem.authors       = ["Daniel Schauenberg"]
  gem.email         = 'd@unwiredcouch.com'
  gem.homepage      = 'https://github.com/mrtazz/knife-wip'
  gem.summary       = "A workflow plugin to track WIP nodes on a chef server"
  gem.description   = "A workflow plugin to track WIP nodes on a chef server"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'chef', '>= 0.10.4'
  gem.add_runtime_dependency 'app_conf', '~> 0.4', '>= 0.4.2'
end
