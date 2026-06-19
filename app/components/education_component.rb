class EducationComponent < ApplicationComponent
  def initialize(schools:)
    @schools = schools
  end

  def render?
    @schools.any?
  end

  private

  attr_reader :schools
end
