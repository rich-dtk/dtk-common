# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dtk-common/version', __FILE__)

# only used for autoincremeting versions in production
prod_version_path = File.expand_path('../lib/dtk-common/prod_version', __FILE__)
if File.exist?("#{prod_version_path}.rb")
  require prod_version_path
else
  DtkCommon::PROD_VERSION = nil
end

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
  gem.version       = DtkCommon::PROD_VERSION || "#{DtkCommon::VERSION}.#{ARGV[3]}".chomp(".")

  gem.add_dependency 'rugged','~> 0.17.0.b7'
  # gem.add_dependency 'sequel','~> 3.40.0'
  # gem.add_dependency 'rdoc','~> 3.12'
end
