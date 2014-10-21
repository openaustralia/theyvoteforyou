class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :async

  has_many :wiki_motions
  has_many :policies

  validates :name, presence: true, uniqueness: true

  def password_required?
    name != User.system_name
  end

  def email_required?
    name != User.system_name
  end

  def api_key
    api_key = read_attribute(:api_key) || User.random_api_key
    update_attribute(:api_key, api_key)
    api_key
  end

  def self.system_name
    "system"
  end

  # System user - used when updating divisions from a rake task
  def self.system
    find_or_create_by!(name: system_name)
  end

  def self.random_api_key
    Digest::MD5.base64digest(rand.to_s + Time.now.to_s)[0...20]
  end
end
