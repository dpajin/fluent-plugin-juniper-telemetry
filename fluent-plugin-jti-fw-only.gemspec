# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "fluent-plugin-jti-fw-only"
  s.version       = '0.0.1'
  s.authors       = ["Dusan Pajin"]
  s.email         = ["dpajin@juniper.net"]

  s.summary       = %q{Fluentd input plugin Juniper telemetry data streaming supporting JTI Firewall sensor counters stats only}
  s.description   = %q{Fluentd input plugin Juniper telemetry data streaming supporting JTI Firewall sensor counters stats only}
  s.homepage      = "https://github.com/dpajin/fluentd-plugin-juniper-telemetry"
  s.license       = 'Apache 2.0'

  #s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^test/}) }
  s.files         = Dir['lib/fluent/plugin/parser*.rb', 'lib/*.rb', 'lib/google/protobuf/*.rb' ]
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = %w(lib)

  s.add_runtime_dependency "fluentd", ">= 0.12.29"
  s.add_runtime_dependency "protobuf"
  s.add_development_dependency "rake"
end
