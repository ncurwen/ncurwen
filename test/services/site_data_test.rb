require "test_helper"
require "view_component/test_helpers"

class SiteDataTest < ActiveSupport::TestCase
  include ViewComponent::TestHelpers

  test "every shipped YAML file loads and conforms to its schema" do
    SiteData::Schema::SCHEMAS.each_key do |name|
      assert_nothing_raised { SiteData.fetch(name) }
    end
  end

  test "garden note dates parse as Date" do
    SiteData.fetch(:garden_notes).each { |entry| assert_kind_of Date, entry[:date] }
  end

  test "components render against the real data" do
    assert_nothing_raised do
      render_inline(WorkHistoryComponent.new(positions: SiteData.fetch(:work_history)))
      render_inline(EducationComponent.new(schools: SiteData.fetch(:education)))
    end
  end

  test "validator reports a missing required field by path" do
    data = { rows: [ { heading: "Languages" } ] } # items missing
    error = assert_raises(SiteData::InvalidData) { SiteData::Validator.call(:tech_stack, data) }
    assert_match "rows[0].items: missing", error.message
  end

  test "validator rejects unknown keys" do
    data = { rows: [ { heading: "Languages", items: [ "Ruby" ], colour: "blue" } ] }
    error = assert_raises(SiteData::InvalidData) { SiteData::Validator.call(:tech_stack, data) }
    assert_match "rows[0].colour: unknown key", error.message
  end

  test "validator checks nested rows" do
    data = { rows: [ { company: "Acme", period: "2020", roles: [ {} ] } ] }
    error = assert_raises(SiteData::InvalidData) { SiteData::Validator.call(:work_history, data) }
    assert_match "rows[0].roles[0].title: missing", error.message
  end
end
