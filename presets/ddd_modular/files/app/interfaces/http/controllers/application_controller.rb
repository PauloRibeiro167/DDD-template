class ApplicationController < ActionController::Base
  prepend_view_path Rails.root.join("app/interfaces/http/views")
  helper_method :body_css_class

  rescue_from ActiveRecord::RecordNotFound do
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    flash.now[:alert] = error.record.errors.full_messages.to_sentence
    fallback_action = action_name == "update" ? :edit : :new
    render fallback_action, status: :unprocessable_entity
  end

  private

  def body_css_class
    "ddd-admin"
  end
end
