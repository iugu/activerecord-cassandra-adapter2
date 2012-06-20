# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "activerecord-cassandra-adapter2/version"

Gem::Specification.new do |s|
  s.name        = "activerecord-cassandra-adapter2"
  s.version     = Activerecord::Cassandra::Adapter2::VERSION
  s.authors     = ["Patrick Negri"]
  s.email       = ["patrick@iugu.com.br"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "activerecord-cassandra-adapter2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_dependency "cassandra-cql"
  s.add_dependency "uuidtools"

end
