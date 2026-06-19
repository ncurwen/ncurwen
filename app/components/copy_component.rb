class CopyComponent < ApplicationComponent
  def initialize(label:, value:)
    @label = label
    @value = value
  end

  private

  attr_reader :label, :value
end
