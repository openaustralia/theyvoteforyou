# frozen_string_literal: true

class Bill < ApplicationRecord
  has_and_belongs_to_many :divisions
end
