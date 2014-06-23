class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
  self.table_name = "pw_dyn_user"

  has_many :wiki_motions
  has_many :policies

  def change_password(new_password)
    self.password = Digest::MD5.hexdigest(new_password.downcase)
  end

  # FIXME This should be an association
  def active_policy
    Policy.find active_policy_id if active_policy_id
  end
end
