# frozen_string_literal: true

initializer "zeitwerk_domains.rb", <<~RUBY
  domains_root = Rails.root.join("app/domains")
  infrastructure_root = Rails.root.join("app/infrastructure")
  interfaces_root = Rails.root.join("app/interfaces")

  Rails.autoloaders.main.ignore(domains_root)
  Rails.autoloaders.main.ignore(infrastructure_root)
  Rails.autoloaders.main.ignore(interfaces_root)

  Rails.autoloaders.main.push_dir(domains_root)
  Rails.autoloaders.main.push_dir(infrastructure_root)
  Rails.autoloaders.main.push_dir(interfaces_root)
RUBY
