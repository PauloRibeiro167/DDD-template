# frozen_string_literal: true

class BackofficeCrudGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_controller
    template "controller.rb.tt", "app/controllers/#{plural_file_name}_controller.rb"
  end

  def create_presenter
    template "presenter.rb.tt", "app/presenters/#{file_name}_presenter.rb"
  end

  def create_views
    available_views.each do |view_name|
      template "#{view_name}.html.erb.tt", "app/views/#{plural_file_name}/#{view_name}.html.erb"
    end
  end

  private

  def available_views
    %w[index show new edit _form]
  end
end
