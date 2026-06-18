module SiteData
  # Declarative shape of each config/site_data/*.yml file, consumed by Validator.
  #
  # Every file is a single top-level key (ROOT) holding an array of rows. Each
  # entry in SCHEMAS describes one row:
  #
  #   { required: { field => type, ... }, optional: { field => type, ... } }
  #
  # where `type` is one of:
  #   :str    — a String
  #   :array  — an Array of Strings
  #   :date   — a Date (loaded via permitted_classes in Loader#read)
  #   a nested row spec ({ required:, optional: }) — an Array of sub-rows
  module Schema
    ROOT = :rows

    SCHEMAS = {
      education: {
        required: { school: :str, credential: :str, period: :str, location: :str },
        optional: { honours: :array }
      },
      work_history: {
        required: { company: :str, period: :str },
        optional: {
          location: :str,
          summary: :str,
          roles: {
            required: { title: :str },
            optional: { period: :str, bullets: :array }
          }
        }
      },
      tech_stack: {
        required: { heading: :str, items: :array }
      },
      garden_notes: {
        required: { date: :date, title: :str, body: :str, tag: :str }
      }
    }.freeze
  end
end
