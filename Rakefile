require "rspec/core/rake_task"
require "yard"

RSpec::Core::RakeTask.new(:spec)

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb", "README.md", "README-ru.md", "coverage-badge.svg"]
  t.options = ["--protected", "--output-dir", "doc", "--readme", "README.md", "--asset", "coverage-badge.svg"]
end

task default: [:spec, :yard]
task docs: :yard
