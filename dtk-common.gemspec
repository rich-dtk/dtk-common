# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dtk-common/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rich PELAVIN"]
  gem.email         = ["rich@reactor8.com"]
  gem.description   = %q{Dtk common is needed to use dtk-client gem, provides common libraries for running DTK CLI.}
  gem.summary       = %q{Common libraries used for DTK CLI client.}
  gem.homepage      = "https://github.com/rich-reactor8/dtk-common"
  gem.licenses      = ["GPL-3.0"]

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "dtk-common"
  gem.require_paths = ["lib"]
  gem.version       = DtkCommon::VERSION

  gem.add_dependency 'rugged','~> 0.17.0.b7'
  gem.add_dependency 'dtk-common-core','0.7.2'
  gem.add_dependency 'colorize','~> 0.5.8'
  # gem.add_dependency 'sequel','~> 3.40.0'
  # gem.add_dependency 'rdoc','~> 3.12'
end
