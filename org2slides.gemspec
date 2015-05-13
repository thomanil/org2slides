# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "org2slides"

Gem::Specification.new do |s|
  s.name        = "org2slides"
  s.version     = OrgToSlides::VERSION
  s.authors     = ["Thomas Kjeldahl Nilsson"]
  s.email       = ["thomas@kjeldahlnilsson.net"]
  s.homepage    = "https://kjeldahlnilsson.net"
  s.summary     = %q{Turn orgfiles into Reveal.js presentations}
  s.description = %q{Turn orgfiles into Reveal.js presentations}

  s.rubyforge_project = "org2slides"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "nokogiri"

  s.add_development_dependency "minitest"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "shoulda-context"
  s.add_development_dependency "org-ruby"
end
