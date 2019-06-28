# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cfme/cloud_services/version'

Gem::Specification.new do |spec|
  spec.name          = "cfme-cloud_services"
  spec.version       = Cfme::CloudServices::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "Red Hat Cloud Services plugin for CloudForms"
  spec.description   = "Red Hat Cloud Services plugin for CloudForms"
  spec.homepage      = "https://github.com/RedHatCloudForms/cfme-cloud_services"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "json-stream", "~> 0.2.0"
end
