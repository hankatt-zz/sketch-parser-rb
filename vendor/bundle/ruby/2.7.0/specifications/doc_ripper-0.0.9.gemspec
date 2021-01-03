# -*- encoding: utf-8 -*-
# stub: doc_ripper 0.0.9 ruby lib

Gem::Specification.new do |s|
  s.name = "doc_ripper".freeze
  s.version = "0.0.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Paul Zaich".freeze]
  s.date = "2019-02-05"
  s.description = "Scrape text from common file formats (.pdf,.doc,.docx, .sketch, .txt) with a single convenient command.".freeze
  s.email = ["pzaich@gmail.com".freeze]
  s.homepage = "https://github.com/pzaich/doc_ripper".freeze
  s.licenses = ["MIT".freeze]
  s.requirements = ["Antiword".freeze, "pdftotext/poppler".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Rip out text from pdf, doc and docx formats".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<CFPropertyList>.freeze, ["~> 2.3"])
    s.add_runtime_dependency(%q<colored>.freeze, ["~> 1.2"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.6"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  else
    s.add_dependency(%q<CFPropertyList>.freeze, ["~> 2.3"])
    s.add_dependency(%q<colored>.freeze, ["~> 1.2"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.6"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
  end
end
