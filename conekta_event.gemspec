$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "conekta_event/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "conekta_event"
  s.version     = ConektaEvent::VERSION
  s.authors     = ["Gerardo Acuña"]
  s.email       = ["gacuna@moneypool.mx"]
  s.homepage    = "http://www.github.com/moneypool/conekta_event"
  s.summary     = "Conekta webhook integration for Rails applications"
  s.description = "Conekta webhook integration for Rails applications"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "activesupport", ">= 3.1"
  s.add_dependency "conekta", "~> 0.5.5"

  s.add_development_dependency "rails", ">= 3.1"
  s.add_development_dependency "rspec-rails", "~> 2.12"
  s.add_development_dependency "webmock", "~> 1.9"
  s.add_development_dependency "appraisal"
  s.add_development_dependency "coveralls"
end
