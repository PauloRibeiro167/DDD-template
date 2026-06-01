# frozen_string_literal: true

gsub_file "config/application.rb", 'config.autoload_lib(ignore: %w[assets tasks])', 'config.autoload_lib(ignore: %w[assets tasks generators])'

api_domain_autoload_config = <<~RUBY
      config.paths.add "app/domains", eager_load: true
      config.paths.add "app/interfaces/http", eager_load: true
      config.paths.add "app/infrastructure", eager_load: true

RUBY

unless File.read("config/application.rb").include?('config.paths.add "app/domains", eager_load: true')
  inject_into_file "config/application.rb", after: "config.generators.system_tests = nil\n" do
    api_domain_autoload_config
  end
end

initializer "zeitwerk_api_lite.rb", <<~RUBY
  Rails.autoloaders.main.push_dir(Rails.root.join("app/domains"))
  Rails.autoloaders.main.push_dir(Rails.root.join("app/interfaces/http"))
  Rails.autoloaders.main.push_dir(Rails.root.join("app/infrastructure"))
RUBY
