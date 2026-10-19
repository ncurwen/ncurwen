namespace :garden do
  desc "Generate the resized/WebP copies of the garden photos (FORCE=1 to rebuild all)"
  task derivatives: :environment do
    GardenDerivatives.call(root: Rails.root.to_s, force: ENV["FORCE"].present?)
  end
end
