RailsCloudflareTurnstile.configure do |c|
  key = Rails.application.credentials.dig(:cloudflare_turnstile, :site_key)
  secret = Rails.application.credentials.dig(:cloudflare_turnstile, :secret_key)
  c.site_key = key
  c.secret_key = secret

  c.enabled = Rails.env.production? && key.present? && secret.present?
  # No mock widget outside production: the gem's mock injects inline styles (and
  # mutates style attributes from JS) that our CSP blocks. With both enabled and
  # mock_enabled false, the widget renders nothing and verification passes — fine
  # for dev/test, and prod uses the real (invisible) widget.
  c.mock_enabled = false
  c.fail_open = true
end
