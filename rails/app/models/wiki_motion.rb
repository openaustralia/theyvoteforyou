class WikiMotion < ActiveRecord::Base
  self.table_name = "pw_dyn_wiki_motion"

  belongs_to :division
end
