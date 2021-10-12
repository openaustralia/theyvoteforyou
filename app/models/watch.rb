# frozen_string_literal: true

class Watch < ApplicationRecord
  belongs_to :watchable, polymorphic: true
  belongs_to :user
end
