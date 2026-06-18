# Base for plain service objects: the one public entry point is Service.call(...),
# which builds an instance and runs its #call. Subclasses put their work in an
# instance #call and keep everything else private.
class ApplicationService
  def self.call(...)
    new(...).call
  end
end
