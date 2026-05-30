# frozen_string_literal: true

class BoundedContextGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_domain_layers
    empty_directory "app/domains/#{file_path}/models"
    empty_directory "app/domains/#{file_path}/services"
    empty_directory "app/domains/#{file_path}/repositories"
    empty_directory "app/domains/#{file_path}/events"
  end

  def create_interface_layers
    empty_directory "app/interfaces/http/controllers/#{file_path}"
    empty_directory "app/interfaces/http/views/#{file_path}"
  end

  def create_example_files
    template "entity.rb.tt", "app/domains/#{file_path}/models/#{file_name.singularize}.rb"
    template "repository.rb.tt", "app/domains/#{file_path}/repositories/#{file_name.singularize}_repository.rb"
    template "service.rb.tt", "app/domains/#{file_path}/services/create_#{file_name.singularize}.rb"
  end
end
