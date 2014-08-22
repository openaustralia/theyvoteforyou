class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :wiki_motions
  has_many :policies
  has_one :active_policy, class_name: "Policy", foreign_key: :dream_id, primary_key: :active_policy_id
end
