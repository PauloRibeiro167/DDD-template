# frozen_string_literal: true

class Api::BaseController < ActionController::API
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from Shared::Errors::ApplicationError, with: :render_domain_error
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found

  private

  def render_success(data:, status: :ok, meta: nil)
    payload = { data: data }
    payload[:meta] = meta if meta.present?

    render json: payload, status: status
  end

  def render_no_content
    head :no_content
  end

  def render_bad_request(error)
    render_error(
      code: "bad_request",
      message: error.message,
      status: :bad_request
    )
  end

  def render_domain_error(error)
    render_error(
      code: error.code,
      message: error.message,
      details: error.details,
      status: error.http_status
    )
  end

  def render_record_invalid(error)
    render_error(
      code: "validation_error",
      message: "Falha de validação",
      details: error.record.errors.to_hash(true),
      status: :unprocessable_entity
    )
  end

  def render_record_not_found(_error)
    render_error(
      code: "not_found",
      message: "Recurso não encontrado",
      status: :not_found
    )
  end

  def render_error(code:, message:, status:, details: nil)
    render json: ErrorSerializer.render(
      code: code,
      message: message,
      details: details
    ), status: status
  end
end
