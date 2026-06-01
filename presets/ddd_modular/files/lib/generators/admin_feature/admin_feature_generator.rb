# frozen_string_literal: true

require "rails/generators"
require "rails/generators/generated_attribute"
require "rails/generators/active_record"

class AdminFeatureGenerator < Rails::Generators::NamedBase
  include ActiveRecord::Generators::Migration

  source_root File.expand_path("templates", __dir__)

  UI_FRAMEWORK_SIGNATURES = {
    tailwind: {
      gem_patterns: [/gem ["']tailwindcss-rails["']/, /gem ["']tailwindcss-ruby["']/],
      file_paths: %w[config/tailwind.config.js config/tailwind.config.cjs app/assets/tailwind/application.css]
    },
    bootstrap: {
      gem_patterns: [/gem ["']bootstrap["']/, /gem ["']bootstrap-icons["']/],
      file_paths: %w[app/assets/stylesheets/application.bootstrap.scss app/assets/stylesheets/bootstrap.scss]
    }
  }.freeze

  UI_CLASS_MAP = {
    css: {
      page_shell: "page-shell",
      page_shell_md: "page-shell page-shell-md",
      page_header: "page-header",
      eyebrow: "eyebrow",
      subtitle: "subtitle",
      surface_card: "surface-card",
      empty_panel: "empty-panel",
      data_table: "data-table",
      actions: "actions",
      header_actions: "header-actions",
      details_grid: "details-grid",
      stacked_form: "stacked-form",
      field: "field",
      field_checkbox: "field field-checkbox",
      input: "input",
      form_actions: "form-actions",
      error_box: "error-box",
      button_primary: "button-primary",
      button_secondary: "button-secondary",
      button_link: "button-link",
      button_link_danger: "button-link danger"
    },
    bootstrap: {
      page_shell: "container py-4 py-lg-5",
      page_shell_md: "container py-4 py-lg-5",
      page_header: "d-flex flex-column flex-lg-row justify-content-between align-items-lg-end gap-3 mb-4",
      eyebrow: "text-uppercase small fw-semibold text-secondary mb-2",
      subtitle: "text-secondary mb-0",
      surface_card: "card shadow-sm border-0",
      empty_panel: "card shadow-sm border-0 text-center p-4",
      data_table: "table table-hover align-middle mb-0",
      actions: "d-flex flex-wrap gap-2 align-items-center",
      header_actions: "d-flex flex-wrap gap-2 align-items-center",
      details_grid: "row row-cols-1 row-cols-md-2 row-cols-xl-3 g-4",
      stacked_form: "d-grid gap-3",
      field: "d-grid gap-2",
      field_checkbox: "form-check pt-2",
      input: "form-control",
      form_actions: "d-flex flex-column flex-md-row gap-2 pt-2",
      error_box: "alert alert-danger mb-0",
      button_primary: "btn btn-success",
      button_secondary: "btn btn-outline-secondary",
      button_link: "btn btn-link text-decoration-none p-0",
      button_link_danger: "btn btn-link text-danger text-decoration-none p-0"
    },
    tailwind: {
      page_shell: "mx-auto max-w-6xl px-5 py-8 md:px-8 md:py-12",
      page_shell_md: "mx-auto max-w-3xl px-5 py-8 md:px-8 md:py-12",
      page_header: "mb-6 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between",
      eyebrow: "mb-2 text-xs font-semibold uppercase tracking-[0.18em] text-amber-700",
      subtitle: "mt-2 max-w-2xl text-sm leading-6 text-stone-500",
      surface_card: "overflow-hidden rounded-[28px] border border-stone-200 bg-gradient-to-b from-stone-50 to-stone-100 p-6 shadow-[0_20px_45px_rgba(86,60,29,0.08)]",
      empty_panel: "rounded-[28px] border border-stone-200 bg-gradient-to-b from-stone-50 to-stone-100 p-8 text-center shadow-[0_20px_45px_rgba(86,60,29,0.08)]",
      data_table: "min-w-full divide-y divide-stone-200",
      actions: "flex flex-col items-start gap-2 md:flex-row md:items-center",
      header_actions: "flex flex-col gap-2 md:flex-row",
      details_grid: "grid gap-5 md:grid-cols-2 xl:grid-cols-3",
      stacked_form: "grid gap-4",
      field: "grid gap-2",
      field_checkbox: "flex items-center gap-2 pt-2",
      input: "w-full rounded-2xl border border-stone-300 bg-stone-50 px-4 py-3 text-stone-900 shadow-sm outline-none transition focus:border-emerald-800 focus:ring-2 focus:ring-emerald-200",
      form_actions: "flex flex-col gap-3 pt-2 md:flex-row md:items-center",
      error_box: "rounded-2xl border border-rose-300 bg-rose-50 p-4 text-rose-800",
      button_primary: "inline-flex items-center justify-center rounded-full bg-emerald-950 px-5 py-3 text-sm font-semibold text-white transition hover:bg-emerald-900",
      button_secondary: "inline-flex items-center justify-center rounded-full bg-stone-200 px-5 py-3 text-sm font-semibold text-stone-700 transition hover:bg-stone-300",
      button_link: "inline-flex items-center text-sm font-semibold text-emerald-900 transition hover:text-emerald-700",
      button_link_danger: "inline-flex items-center text-sm font-semibold text-rose-700 transition hover:text-rose-600"
    }
  }.freeze

  argument :attributes, type: :array, default: [], banner: "field:type field:type"

  def self.next_migration_number(dirname)
    ActiveRecord::Generators::Base.next_migration_number(dirname)
  end

  def create_domain_layers
    empty_directory domain_root
    empty_directory "#{domain_root}/models"
    empty_directory "#{domain_root}/repositories"
    empty_directory "#{domain_root}/services"
  end

  def create_interface_layers
    empty_directory controller_directory
    empty_directory presenter_directory
    empty_directory form_directory
    empty_directory view_directory
  end

  def create_migration
    migration_template "migration.rb.tt", "db/migrate/create_#{table_name}.rb"
  end

  def create_model
    template "model.rb.tt", "#{model_directory}/#{file_name}_record.rb"
  end

  def create_entity
    template "entity.rb.tt", "#{domain_root}/models/#{file_name}.rb"
  end

  def create_repository
    template "repository.rb.tt", "#{domain_root}/repositories/#{file_name}_repository.rb"
  end

  def create_services
    template "service_create.rb.tt", "#{domain_root}/services/create_#{file_name}.rb"
    template "service_update.rb.tt", "#{domain_root}/services/update_#{file_name}.rb"
    template "service_destroy.rb.tt", "#{domain_root}/services/destroy_#{file_name}.rb"
  end

  def create_interface_objects
    template "form.rb.tt", "#{form_directory}/#{file_name}_form.rb"
    template "presenter.rb.tt", "#{presenter_directory}/#{file_name}_presenter.rb"
    template "controller.rb.tt", "#{controller_directory}/#{table_name}_controller.rb"
  end

  def create_views
    %w[index show new edit _form].each do |view_name|
      template "#{view_name}.html.erb.tt", "#{view_directory}/#{view_name}.html.erb"
    end
  end

  def add_routes
    route route_definition
  end

  private

  def parsed_attributes
    @parsed_attributes ||= attributes.map { |attribute| Rails::Generators::GeneratedAttribute.parse(attribute) }
  end

  def table_name
    file_name.pluralize
  end

  def domain_root
    "app/domains/#{resource_namespace_path}/#{table_name}"
  end

  def controller_directory
    "app/interfaces/http/controllers/#{resource_namespace_path}"
  end

  def presenter_directory
    "app/interfaces/http/presenters/#{resource_namespace_path}/#{table_name}"
  end

  def form_directory
    "app/interfaces/http/forms/#{resource_namespace_path}/#{table_name}"
  end

  def view_directory
    "app/interfaces/http/views/#{resource_namespace_path}/#{table_name}"
  end

  def model_directory
    resource_namespace_path.empty? ? "app/models" : "app/models/#{resource_namespace_path}"
  end

  def resource_namespace_path
    class_path.join("/")
  end

  def domain_module_names
    class_path.map(&:camelize) + [table_name.camelize]
  end

  def controller_module_names
    class_path.map(&:camelize)
  end

  def route_helper_prefix
    (class_path + [file_name]).join("_")
  end

  def plural_route_helper
    (class_path + [table_name]).join("_")
  end

  def member_path_call(argument = "resource.id")
    "#{route_helper_prefix}_path(#{argument})"
  end

  def plural_path_call
    "#{plural_route_helper}_path"
  end

  def new_member_path_call
    "new_#{route_helper_prefix}_path"
  end

  def edit_member_path_call(argument = "resource.id")
    "edit_#{route_helper_prefix}_path(#{argument})"
  end

  def controller_class_name
    "#{table_name.camelize}Controller"
  end

  def form_class_name
    "#{file_name.camelize}Form"
  end

  def presenter_class_name
    "#{file_name.camelize}Presenter"
  end

  def model_class_name
    "#{file_name.camelize}Record"
  end

  def domain_module_opening(indent: 0)
    domain_module_names.map.with_index do |module_name, index|
      "#{'  ' * (indent + index)}module #{module_name}"
    end.join("\n")
  end

  def domain_module_closing(indent: 0)
    domain_module_names.size.times.map do |index|
      "#{'  ' * (indent + domain_module_names.size - index - 1)}end"
    end.join("\n")
  end

  def controller_module_opening
    controller_module_names.map.with_index do |module_name, index|
      "#{'  ' * index}module #{module_name}"
    end.join("\n")
  end

  def controller_module_closing
    controller_module_names.size.times.map do |index|
      "#{'  ' * (controller_module_names.size - index - 1)}end"
    end.join("\n")
  end

  def route_definition
    lines = class_path.map.with_index do |namespace, index|
      "#{'  ' * index}namespace :#{namespace} do"
    end

    lines << "#{'  ' * class_path.size}resources :#{table_name}"
    lines.concat(class_path.size.times.map do |index|
      "#{'  ' * (class_path.size - index - 1)}end"
    end)
    lines.join("\n")
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

  def entity_initializer_signature
    entity_keywords.map { |name| "#{name}: nil" }.join(", ")
  end

  def entity_reader_names
    entity_keywords.join(", ")
  end

  def form_accessor_names
    form_fields.map(&:name).join(", ")
  end

  def form_attribute_hash_lines
    if form_fields.empty?
      "      {}"
    else
      form_fields.map { |attribute| "      #{attribute.name}: #{attribute.name}" }.join(",\n")
    end
  end

  def form_resource_hash_lines
    if form_fields.empty?
      "        {}"
    else
      form_fields.map { |attribute| "        #{attribute.name}: resource.#{attribute.name}" }.join(",\n")
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

  def table_headers
    (form_fields.map(&:name) + %w[created_at]).uniq
  end

  def input_field(attribute)
    field_method = field_method_for(attribute)

    if field_method == :check_box
      checkbox_markup(attribute)
    else
      standard_field_markup(attribute, field_method)
    end
  end

  def form_fields_markup
    if form_fields.empty?
      <<~ERB.chomp
        <p class="empty-state">
          Defina campos ao gerar a feature, por exemplo: <code>rails g admin_feature admin/post title:string status:string published_at:datetime</code>
        </p>
      ERB
    else
      form_fields.map { |attribute| input_field(attribute) }.join("\n\n")
    end
  end

  def generated_erb(code)
    "<%= #{code} %>"
  end

  def generated_block(code)
    "<% #{code} %>"
  end

  def ui_framework
    @ui_framework ||= detect_ui_framework
  end

  def ui_class(key)
    UI_CLASS_MAP.fetch(ui_framework).fetch(key)
  end

  def detect_ui_framework
    return :tailwind if framework_detected?(:tailwind)
    return :bootstrap if framework_detected?(:bootstrap)

    :css
  end

  def framework_detected?(framework_name)
    signature = UI_FRAMEWORK_SIGNATURES.fetch(framework_name)
    gemfile_matches?(signature[:gem_patterns]) || expected_files_present?(signature[:file_paths])
  end

  def gemfile_matches?(patterns)
    return false unless File.exist?("Gemfile")

    content = File.read("Gemfile")
    patterns.any? { |pattern| content.match?(pattern) }
  end

  def expected_files_present?(paths)
    paths.any? { |path| File.exist?(path) }
  end

  def field_method_for(attribute)
    case attribute.type
    when :text
      :text_area
    when :boolean
      :check_box
    when :date
      :date_field
    when :datetime, :timestamp
      :datetime_local_field
    when :integer, :float, :decimal
      :number_field
    else
      :text_field
    end
  end

  def checkbox_markup(attribute)
    case ui_framework
    when :bootstrap
      <<~ERB.chomp
        <div class="#{ui_class(:field_checkbox)}">
          <%= form.check_box :#{attribute.name}, class: "form-check-input" %>
          <%= form.label :#{attribute.name}, class: "form-check-label" %>
        </div>
      ERB
    when :tailwind
      <<~ERB.chomp
        <div class="#{ui_class(:field_checkbox)}">
          <%= form.check_box :#{attribute.name}, class: "h-4 w-4 rounded border-stone-300 text-emerald-900 focus:ring-emerald-200" %>
          <%= form.label :#{attribute.name}, class: "text-sm font-medium text-stone-700" %>
        </div>
      ERB
    else
      <<~ERB.chomp
        <div class="#{ui_class(:field_checkbox)}">
          <label><%= form.check_box :#{attribute.name} %> <%= form.object.class.human_attribute_name(:#{attribute.name}) %></label>
        </div>
      ERB
    end
  end

  def standard_field_markup(attribute, field_method)
    label_class =
      case ui_framework
      when :bootstrap
        "form-label"
      when :tailwind
        "text-sm font-medium text-stone-700"
      else
        nil
      end

    <<~ERB.chomp
      <div class="#{ui_class(:field)}">
        <%= form.label :#{attribute.name}#{label_class ? %(, class: "#{label_class}") : ""} %>
        <%= form.#{field_method} :#{attribute.name}, class: "#{ui_class(:input)}" %>
      </div>
    ERB
  end
end
