# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # TODO: Re-enable :async when upgraded Devise to 4.x and Rails to 5.x
  # devise :database_authenticatable, :registerable, :confirmable,
  #        :recoverable, :rememberable, :trackable, :validatable, :async
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  # If we're ever in a situation where a user has edited policies
  # but needs to be deleted then we will need to change the dependent
  # options here
  has_many :wiki_motions, dependent: :restrict_with_exception
  has_many :policies, dependent: :restrict_with_exception
  has_many :watches, dependent: :destroy

  validates :name, presence: true

  def password_required?
    name != User.system_name && (!persisted? || !password.nil? || !password_confirmation.nil?)
  end

  def email_required?
    name != User.system_name
  end

  def api_key
    if self[:api_key]
      self[:api_key]
    else
      api_key = User.random_api_key
      update(api_key: api_key)
      api_key
    end
  end

  def watched_policy_ids
    watches.where(watchable_type: "Policy").collect(&:watchable_id)
  end

  def watched_policies
    Policy.where(id: watched_policy_ids)
  end

  def unwatched_policies
    Policy.where.not(id: watched_policy_ids)
  end

  def watching?(object)
    !!watches.find_by(watchable_type: object.class.to_s, watchable_id: object.id)
  end

  def toggle_policy_watch(policy)
    watch = policy.watches.find_by(user: self)
    if watch
      watch.destroy!
    else
      policy.watches.create!(user: self)
    end
  end

  def recent_changes(size)
    changes = PaperTrail::Version.order(created_at: :desc).where(whodunnit: self).limit(size) +
              WikiMotion.order(created_at: :desc).where(user: self).limit(size)
    changes.sort_by { |v| -v.created_at.to_i }.take(size)
  end

  def self.system_name
    "system"
  end

  # System user - used when updating divisions from a rake task
  def self.system
    find_or_create_by!(name: system_name)
  end

  def self.random_api_key
    Digest::MD5.base64digest(rand.to_s + Time.zone.now.to_s)[0...20]
  end

  # Send all devise emails in the background
  # See https://github.com/heartcombo/devise#activejob-integration
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
