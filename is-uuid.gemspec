Gem::Specification::new do |s|
  s.name = "is-enum"
  s.version = "0.8.0"
  s.summary = "UUID class implementation"
  s.description = "UUID class implementation with fast comparision and Sequel compatibility."
  s.authors = ["Ivan Shikhalev"]
  s.email = ["shikhalev@gmail.com"]
  s.files = Dir["lib/**/*", "README.md", "LICENSE"]
  s.homepage = "https://github.com/inat-get/is-enum"
  s.license = "GPL-3.0-or-later"

  s.required_ruby_version = "~> 3.4"

  s.add_development_dependency 'sequel', '~> 5.100'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency "rake", "~> 13.3"
  s.add_development_dependency "simplecov", "~> 0.22.0"
  s.add_development_dependency "yard", "~> 0.9"
  s.add_development_dependency "redcarpet", "~> 3.6"
end
