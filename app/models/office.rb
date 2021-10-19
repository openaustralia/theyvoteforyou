# frozen_string_literal: true

class Office < ApplicationRecord
  has_one :person
end
