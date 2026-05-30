# frozen_string_literal: true

class ErrorSerializer
  def self.render(code:, message:, details: nil)
    payload = {
      error: {
        code: code,
        message: message
      }
    }

    payload[:error][:details] = details if details.present?
    payload
  end
end
