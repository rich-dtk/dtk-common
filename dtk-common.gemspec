# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dtk-common/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rich PELAVIN"]
  gem.email         = ["rich@reactor8.com"]
  gem.description   = %q{Dtk common is needed to use dtk-client gem, provides common libraries for running DTK CLI.}
  gem.summary       = %q{Common libraries used for DTK CLI client.}
  gem.homepage      = "https://github.com/rich-reactor8/dtk-common"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "dtk-common"
  gem.require_paths = ["lib"]
  gem.version       = DtkCommon::VERSION
end
