# frozen_string_literal: true

generate "rspec:install"
remove_dir "test" if File.exist?("test")
