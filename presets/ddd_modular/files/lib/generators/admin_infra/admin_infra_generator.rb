# frozen_string_literal: true

require "rails/generators"
require "rails/generators/generated_attribute"
require "rails/generators/active_record"

class AdminInfraGenerator < Rails::Generators::NamedBase
  include ActiveRecord::Generators::Migration

  source_root File.expand_path("templates", __dir__)

  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  def self.next_migration_number(dirname)
    ActiveRecord::Generators::Base.next_migration_number(dirname)
  end

  def create_migration
    migration_template "migration.rb.tt", "db/migrate/create_#{table_name}.rb"
  end

  def create_model
    template "model.rb.tt", "#{package_root}/infrastructure/active_record/models/#{file_name}_record.rb"
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

  def model_class_name
    "#{file_name.camelize}Record"
  end

  def infrastructure_model_namespace
    package_namespace("Infrastructure", "ActiveRecord", "Models", model_class_name)
  end

  def domain_entity_namespace
    package_namespace("Domain", "Entities", file_name.camelize)
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

  def record_attribute_hash_lines(source:)
    values = entity_keywords.map { |name| "          #{name}: #{source}.#{name}" }
    values.join(",\n")
  end

  def model_attribute_lines
    if parsed_attributes.empty?
      "      # t.string :title\n      # t.text :description"
    else
      parsed_attributes.map { |attribute| "      t.#{attribute.type} :#{attribute.name}" }.join("\n")
    end
  end
end
