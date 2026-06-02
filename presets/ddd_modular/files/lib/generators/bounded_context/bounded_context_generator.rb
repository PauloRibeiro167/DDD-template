# frozen_string_literal: true

require "rails/generators"
require "rails/generators/generated_attribute"
require "rails/generators/active_record"

class BoundedContextGenerator < Rails::Generators::NamedBase
  include ActiveRecord::Generators::Migration

  source_root File.expand_path("templates", __dir__)

  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  def self.next_migration_number(dirname)
    ActiveRecord::Generators::Base.next_migration_number(dirname)
  end

  def create_domain_layers
    empty_directory package_root
    empty_directory "#{package_root}/public"
    empty_directory "#{package_root}/application"
    empty_directory "#{package_root}/application/use_cases"
    empty_directory "#{package_root}/application/event_handlers"
    empty_directory "#{package_root}/domain"
    empty_directory "#{package_root}/domain/entities"
    empty_directory "#{package_root}/domain/value_objects"
    empty_directory "#{package_root}/domain/events"
    empty_directory "#{package_root}/domain/repositories"
    empty_directory "#{package_root}/infrastructure"
    empty_directory "#{package_root}/infrastructure/active_record"
    empty_directory "#{package_root}/infrastructure/active_record/models"
    empty_directory "#{package_root}/infrastructure/repositories"
    empty_directory "#{package_root}/infrastructure/messaging"
  end

  def create_interface_layers
    empty_directory "#{package_root}/presentation"
    empty_directory "#{package_root}/presentation/controllers"
    empty_directory "#{package_root}/presentation/serializers"
    empty_directory "#{package_root}/presentation/views"
  end

  def create_example_files
    create_file "#{package_root}/package.yml", package_manifest
    migration_template "migration.rb.tt", "db/migrate/create_#{table_name}.rb"
    template "model.rb.tt", "#{package_root}/infrastructure/active_record/models/#{file_name.singularize}_record.rb"
    template "entity.rb.tt", "#{package_root}/domain/entities/#{file_name.singularize}.rb"
    template "repository.rb.tt", "#{package_root}/domain/repositories/#{file_name.singularize}_repository.rb"
    template "service.rb.tt", "#{package_root}/application/use_cases/create_#{file_name.singularize}.rb"
  end

  private

  def parsed_attributes
    @parsed_attributes ||= attributes.map { |attribute| Rails::Generators::GeneratedAttribute.parse(attribute) }
  end

  def table_name
    file_name.pluralize
  end

  def model_class_name
    "#{file_name.singularize.camelize}Record"
  end

  def model_attribute_lines
    if parsed_attributes.empty?
      "      # t.string :name\n      # t.text :description"
    else
      parsed_attributes.map { |attribute| "      t.#{attribute.type} :#{attribute.name}" }.join("\n")
    end
  end

  def package_root
    "app/domains/#{file_path}"
  end

  def package_namespace(*layers)
    ([*class_path.map(&:camelize)] + layers.map(&:camelize)).join("::")
  end

  def package_namespace_opening(*layers, indent: 0)
    ([*class_path.map(&:camelize)] + layers.map(&:camelize)).each_with_index.map do |module_name, index|
      "#{'  ' * (indent + index)}module #{module_name}"
    end.join("\n")
  end

  def package_namespace_closing(*layers, indent: 0)
    size = class_path.length + layers.length
    size.times.map do |index|
      "#{'  ' * (indent + size - index - 1)}end"
    end.join("\n")
  end

  def package_manifest
    <<~YAML
      name: #{file_path.tr('/', '-')}
      enforce_privacy: true
    YAML
  end
end
