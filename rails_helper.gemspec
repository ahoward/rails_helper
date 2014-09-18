## rails_helper.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "rails_helper"
  spec.version = "2.2.2"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "rails_helper"
  spec.description = "description: rails_helper kicks the ass"
  spec.license = "Ruby"

  spec.files =
["README.md", "Rakefile", "lib", "lib/rails_helper.rb", "rails_helper.gemspec"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["rails_current", " >= 1.0"])
  
    spec.add_dependency(*["rails_default_url_options", " >= 1.0"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/rails_helper"
end
