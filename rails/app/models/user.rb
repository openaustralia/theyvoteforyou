class User < ActiveRecord::Base
  self.table_name = "pw_dyn_user"

  has_many :wiki_motions
  has_many :policies

  def change_password(new_password)
    self.password = Digest::MD5.hexdigest(new_password.downcase)
  end
end
