# frozen_string_literal: true

class Api::BaseController < ActionController::API
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ::Shared::Errors::ApplicationError, with: :render_domain_error
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
    render json: ::Api::ErrorSerializer.render(
      code: code,
      message: message,
      details: details
    ), status: status
  end

  def current_identity_payload
    return @current_identity_payload if defined?(@current_identity_payload)

    token = bearer_token
    @current_identity_payload = token.present? ? ::Security::TokenService.decode_access_token(token) : nil
  end

  def current_identity_user
    return @current_identity_user if defined?(@current_identity_user)

    user_id = current_identity_payload&.fetch("sub", nil)
    @current_identity_user = user_id ? ::Identity::Models::User.find_by(id: user_id) : nil
  end

  def current_identity_session
    return @current_identity_session if defined?(@current_identity_session)

    session_id = current_identity_payload&.fetch("sid", nil)
    @current_identity_session = session_id ? ::Identity::Models::AccessSession.find_by(id: session_id) : nil
  end

  def authenticate_identity_user!
    return if current_identity_user.present? && current_identity_session.present? && !current_identity_session.revoked?

    render_error(
      code: "unauthorized",
      message: "Autenticação inválida ou expirada",
      status: :unauthorized
    )
  end

  def bearer_token
    authorization_header = request.headers["Authorization"].to_s
    scheme, token = authorization_header.split(" ", 2)

    return if scheme.to_s.downcase != "bearer"

    token
  end

  def authorize_policy!(policy_class, action, record = nil)
    policy = policy_class.new(current_identity_user, record)
    allowed = policy.public_send("#{action}?")

    return if allowed

    render_error(
      code: "forbidden",
      message: "Acesso não autorizado para esta ação",
      status: :forbidden
    )
  end
end
