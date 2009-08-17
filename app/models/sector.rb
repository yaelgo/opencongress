class Sector < ActiveRecord::Base
  validates_uniqueness_of :name

  has_many :person_sectors, :include => :person
  has_many :people, :through => :person_sectors
  has_many :comments, :as => :commentable
  has_many :page_views, :as => :viewable


  # forward slashes in the URL were breaking the links
  #def to_param
  #  "#{id}_#{url_name}"
  #end

  @@DISPLAY_OBJECT_NAME = 'Industry'
  
  def display_object_name
    @@DISPLAY_OBJECT_NAME
  end
  
  def views(seconds = 0)
    # if the view_count is part of this instance's @attributes use that; otherwise, count
    return @attributes['view_count'] if @attributes['view_count']
    
    if seconds <= 0
      page_views.count
    else
      page_views.count(:conditions => ["created_at > ?", seconds.ago])
    end
  end
  
  def self.full_text_search(q, options = {})
    Sector.find_by_sql(["SELECT *, rank(fti_names, ?, 1) as tsearch_rank FROM sectors 
                        WHERE fti_names @@ to_tsquery('english', ?) order by tsearch_rank DESC;", q, q])
  end
  
  def ident
    "Industry #{id}"
  end
  
  private
  def url_name
    name.gsub(/[\.\(\)]/, "").gsub(/[-\s]+/, "_").downcase
  end
end
