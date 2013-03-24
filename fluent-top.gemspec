$:.push File.expand_path("../lib", __FILE__)
require "fluent-top/version"

Gem::Specification.new do |s|
  s.name        = "fluent-top"
  s.version     = Fluent::Top::VERSION
  s.authors     = ["Masahiro Nakagawa"]
  s.email       = ["repeatedly@gmail.com"]
  s.homepage    = "https://github.com/repeatedly/fluent-top"
  s.summary     = %q{top for Fluentd}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  gem.add_dependency "fluentd", "~> 0.10.9"
  gem.add_dependency "hirb", "~> 0.7.1"
end
