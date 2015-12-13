# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'iparser/version'

Gem::Specification.new do |spec|
  spec.name          = "iparser"
  spec.version       = Iparser::VERSION
  spec.authors       = ["gera-gas"]
  spec.email         = ["gera_box@mail.ru"]

  spec.summary       = %q{Universal parser machine implementation with interactive mode. Can be used as a parser engine.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/gera-gas/iparser"
  spec.license       = "MIT"
  spec.files         = ["lib/iparser.rb", "lib/iparser/state.rb", "lib/iparser/machine.rb", "lib/iparser/version.rb"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
