class WorkHistoryComponent < ApplicationComponent
  def self.anchor(company)
    "work-#{company.parameterize}"
  end

  def initialize(positions:)
    @positions = positions
  end

  def render?
    @positions.any?
  end

  private

  attr_reader :positions
end
