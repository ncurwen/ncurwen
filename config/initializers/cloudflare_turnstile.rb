RailsCloudflareTurnstile.configure do |c|
  key = Rails.application.credentials.dig(:cloudflare_turnstile, :site_key)
  secret = Rails.application.credentials.dig(:cloudflare_turnstile, :secret_key)
  c.site_key = key
  c.secret_key = secret

  c.enabled = Rails.env.production? && key.present? && secret.present?
  c.mock_enabled = Rails.env.development?
  c.fail_open = true
end
