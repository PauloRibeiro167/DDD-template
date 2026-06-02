# frozen_string_literal: true

require "rails/generators"

class AdminFeatureGenerator < Rails::Generators::NamedBase
  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  class_option :only,
               type: :array,
               default: [],
               desc: "Gera apenas grupos especificos: structure, domain, infra, interface, views, routes"

  class_option :skip,
               type: :array,
               default: [],
               desc: "Ignora grupos especificos: structure, domain, infra, interface, views, routes"

  def invoke_generators
    args = [name] + attributes.map { |a| "#{a.name}:#{a.type}" }

    invoke "admin_domain", args unless skip_domain?
    invoke "admin_infra", args unless skip_infra?
    invoke "admin_ui", args unless skip_ui?
  end

  private

  def normalized_groups(values)
    Array(values).map { |value| value.to_s.downcase.strip }.reject(&:empty?)
  end

  def enabled_groups
    @enabled_groups ||= begin
      available = %w[structure domain infra interface views routes]
      only = normalized_groups(options[:only])
      skip = normalized_groups(options[:skip])

      selected = only.empty? ? available : (only & available)
      selected - skip
    end
  end

  def group_enabled?(group)
    enabled_groups.include?(group)
  end

  def skip_domain?
    !(group_enabled?("structure") || group_enabled?("domain"))
  end

  def skip_infra?
    !group_enabled?("infra")
  end

  def skip_ui?
    !(group_enabled?("interface") || group_enabled?("views") || group_enabled?("routes"))
  end
end
