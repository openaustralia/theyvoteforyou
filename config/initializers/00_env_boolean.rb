# frozen_string_literal: true

# Least-surprise boolean parsing for ENV var flags: nil, blank, and false-like values ("0", "false",
# "off", "f", case-insensitive) are false; anything else is true. A bare `if ENV["FOO"]` treats any set
# value, including "0" and "false", as true, since Ruby only treats nil/false as falsy. See
# docs/DECISIONS.md. Not available in config/puma.rb, which runs before this initializer.
#
# Gotcha for non rubiest: "no" evaluates as true as does "yes", use "false" or "0" or "off" instead
class << ENV
  def true?(key)
    !!ActiveModel::Type::Boolean.new.cast(fetch(key, nil))
  end
end
