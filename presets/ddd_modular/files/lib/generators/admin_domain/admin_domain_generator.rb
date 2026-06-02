# frozen_string_literal: true

require "rails/generators"
require "rails/generators/generated_attribute"

class AdminDomainGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  def create_domain_layers
    empty_directory package_root
    empty_directory "#{package_root}/public"
    empty_directory "#{package_root}/application"
    empty_directory "#{package_root}/application/use_cases"
    empty_directory "#{package_root}/domain"
    empty_directory "#{package_root}/domain/entities"
    empty_directory "#{package_root}/domain/repositories"
    empty_directory "#{package_root}/infrastructure"
    empty_directory "#{package_root}/infrastructure/active_record"
    empty_directory "#{package_root}/infrastructure/active_record/models"
    create_file "#{package_root}/package.yml", package_manifest unless File.exist?("#{package_root}/package.yml")
  end

  def create_entity
    template "entity.rb.tt", "#{package_root}/domain/entities/#{file_name}.rb"
  end

  def create_repository
    template "repository.rb.tt", "#{package_root}/domain/repositories/#{file_name}_repository.rb"
  end

  def create_services
    template "service_create.rb.tt", "#{package_root}/application/use_cases/create_#{file_name}.rb"
    template "service_update.rb.tt", "#{package_root}/application/use_cases/update_#{file_name}.rb"
    template "service_destroy.rb.tt", "#{package_root}/application/use_cases/destroy_#{file_name}.rb"
  end

  private

  def parsed_attributes
    @parsed_attributes ||= attributes.map { |attribute| Rails::Generators::GeneratedAttribute.parse(attribute) }
  end

  def table_name
    file_name.pluralize
  end

  def package_root
    "app/domains/#{resource_namespace_path}"
  end

  def resource_namespace_path
    class_path.join("/")
  end

  def package_module_names
    class_path.map(&:camelize)
  end

  def package_namespace(*layers)
    (package_module_names + layers.map(&:camelize)).join("::")
  end

  def package_namespace_opening(*layers, indent: 0)
    (package_module_names + layers.map(&:camelize)).map.with_index do |module_name, index|
      "#{'  ' * (indent + index)}module #{module_name}"
    end.join("\n")
  end

  def package_namespace_closing(*layers, indent: 0)
    size = package_module_names.length + layers.length
    size.times.map do |index|
      "#{'  ' * (indent + size - index - 1)}end"
    end.join("\n")
  end

  def form_fields
    parsed_attributes.reject(&:reference?)
  end

  def entity_keywords
    @entity_keywords ||= begin
      base = %w[id created_at updated_at]
      dynamic = form_fields.map(&:name)
      (base + dynamic).uniq
    end
  end

  def domain_entity_namespace
    package_namespace("Domain", "Entities", file_name.camelize)
  end

  def domain_repository_namespace
    package_namespace("Domain", "Repositories", "#{file_name.camelize}Repository")
  end

  def application_use_case_namespace(action)
    package_namespace("Application", "UseCases", "#{action.to_s.camelize}#{file_name.camelize}")
  end

  def package_manifest
    <<~YAML
      name: #{resource_namespace_path.tr('/', '-')}
      enforce_privacy: true
    YAML
  end

  def entity_initializer_signature
    entity_keywords.map { |name| "#{name}: nil" }.join(", ")
  end

  def entity_reader_names
    entity_keywords.join(", ")
  end

  def record_attribute_hash_lines(source:)
    values = entity_keywords.map { |name| "          #{name}: #{source}.#{name}" }
    values.join(",\n")
  end
end
