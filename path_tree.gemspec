# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'path_tree/version'
Gem::Specification.new do |spec|
  spec.name          = 'path_tree'
  spec.version       = PathTree::VERSION
  spec.authors       = ['Brian Durand', 'Milan Dobrota']
  spec.email         = ['mdobrota@tribpub.com']
  spec.summary       = 'Helper module for constructing tree data structures'
  spec.description   = 'Module that defines a tree data structure based on a path.'
  spec.homepage      = ''

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activerecord', '>= 3.2.0', '< 4.3'

  spec.add_development_dependency 'rspec', '~> 2.99'
  spec.add_development_dependency 'sqlite3', '>= 0'

  spec.add_development_dependency 'bundler'  , '~> 1.7'
  spec.add_development_dependency 'rake'     , '~> 10.0'
  spec.add_development_dependency 'appraisal', '~> 2.0'
end
