# Extensions to core Ruby.

class String
  
  # Stolen-ish in parts from ActiveSupport::Inflector.
  def camelize
    self.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
  
end