# frozen_string_literal: true

# Least-surprise boolean parsing for ENV var flags: nil, blank, and false-like values ("0", "false",
# "off", "f", all lower or all upper case) are false; anything else, including "False", is true. A bare
# `if ENV["FOO"]` treats any set value, including "0" and "false", as true, since Ruby only treats nil/false
# as falsy. Not available in config/puma.rb or config/environments/*.rb, which load before this initializer.
# See docs/adr/0008-boolean-env-flags-use-env-true.md.
#
# Gotcha for non-Rubyists: "no" counts as true, as does "yes"; use "false", "0" or "off" instead
class << ENV
  def true?(key)
    !!ActiveModel::Type::Boolean.new.cast(fetch(key, nil))
  end
end
