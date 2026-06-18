require "test_helper"
require "capybara/cuprite"

Capybara.server = :puma, { Silent: true }

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1400, 1400 ],
    headless: ENV.fetch("HEADLESS", "true") != "false",
    process_timeout: 20,
    timeout: 15
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite
end
