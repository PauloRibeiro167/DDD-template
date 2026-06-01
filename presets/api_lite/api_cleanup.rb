# frozen_string_literal: true

def remove_gem_declaration(gem_name)
  return unless File.exist?("Gemfile")

  gsub_file "Gemfile", /^\s*gem ["']#{Regexp.escape(gem_name)}["'].*\n/, ""
end

%w[
  importmap-rails
  turbo-rails
  stimulus-rails
  jbuilder
  propshaft
].each do |gem_name|
  remove_gem_declaration(gem_name)
end

remove_dir "app/javascript" if Dir.exist?("app/javascript")
remove_dir "app/assets" if Dir.exist?("app/assets")
remove_dir "app/views" if Dir.exist?("app/views")
remove_dir "vendor/javascript" if Dir.exist?("vendor/javascript")

remove_file "config/importmap.rb" if File.exist?("config/importmap.rb")
remove_file "bin/importmap" if File.exist?("bin/importmap")
remove_file "config/initializers/assets.rb" if File.exist?("config/initializers/assets.rb")
remove_file "config/initializers/content_security_policy.rb" if File.exist?("config/initializers/content_security_policy.rb")

gsub_file "config/application.rb", /^(\s*)config\.api_only = .*$/, ""

inject_into_file "config/application.rb", after: "config.generators.system_tests = nil\n" do
  <<~RUBY
        config.api_only = true
  RUBY
end unless File.read("config/application.rb").include?("config.api_only = true")

%w[
  config/environments/development.rb
  config/environments/test.rb
  config/environments/production.rb
].each do |environment_file|
  next unless File.exist?(environment_file)

  gsub_file environment_file, /^\s*config\.assets\..*\n/, ""
  gsub_file environment_file, /^\s*config\.action_view\..*\n/, ""
end
