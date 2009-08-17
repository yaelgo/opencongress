class State < ActiveRecord::Base
  has_many :districts
  
  has_many :representatives, :class_name => "Person", :finder_sql => 'SELECT people.* from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'rep\' AND roles.enddate > \'#{Time.new.to_s(:db)}\' ORDER BY people.district::text::integer', :counter_sql => 'SELECT COUNT(people.id) from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'rep\' AND roles.enddate > \'#{Time.new.to_s(:db)}\''

  has_many :senators, :class_name => "Person", :finder_sql => 'SELECT people.* from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'sen\' AND roles.enddate > \'#{Time.new.to_s(:db)}\' ORDER BY people.district::text::integer', :counter_sql => 'SELECT COUNT(people.id) from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'sen\' AND roles.enddate > \'#{Time.new.to_s(:db)}\''

  has_many :republican_representatives, :class_name => "Person", :finder_sql => 'SELECT people.* from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'rep\' AND people.party = \'Republican\' AND roles.enddate > \'#{Time.new.to_s(:db)}\' ORDER BY people.district', :counter_sql => 'SELECT COUNT(people.id) from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'rep\' AND people.party = \'Republican\' AND roles.enddate > \'#{Time.new.to_s(:db)}\''

  has_many :democrat_representatives, :class_name => "Person", :finder_sql => 'SELECT people.* from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'rep\' AND people.party = \'Democrat\' AND roles.enddate > \'#{Time.new.to_s(:db)}\' ORDER BY people.district', :counter_sql => 'SELECT COUNT(people.id) from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'rep\' AND people.party = \'Democrat\' AND roles.enddate > \'#{Time.new.to_s(:db)}\''

  has_many :other_representatives, :class_name => "Person", :finder_sql => 'SELECT people.* from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'rep\' AND people.party != \'Democrat\' AND people.party != \'Republican\' AND roles.enddate > \'#{Time.new.to_s(:db)}\' ORDER BY people.district', :counter_sql => 'SELECT COUNT(people.id) from people LEFT OUTER JOIN roles ON roles.person_id = people.id WHERE people.state = \'#{self.abbreviation}\' AND roles.role_type=\'rep\' AND people.party != \'Democrat\' AND people.party != \'Republican\' AND roles.enddate > \'#{Time.new.to_s(:db)}\''  

  def to_param
    self.abbreviation
  end

  def user_count
    User.count_by_solr("my_state:#{abbreviation}")    
  end

  
  def users
    User.find_by_solr("my_state:#{abbreviation}", :facets => {:fields => [:public_actions, :public_tracking, :my_bills_supported, :my_bills_opposed, 
                           :my_committees_tracked, :my_bills_tracked, :my_people_tracked, :my_issues_tracked,
                           :my_approved_reps, :my_approved_sens, :my_disapproved_reps, :my_disapproved_sens], :limit => 10, :sort => true}, 
                           #:browse => ["public_tracking:true", "public_actions:true"]}
                            :order => "last_login desc")
  end
  
  def tracking_suggestions
    facets = self.users.facets
    my_trackers = 0
    facet_results_hsh = {:my_bills_supported_facet => [], 
                         :my_people_tracked_facet => [], 
                         :my_issues_tracked_facet => [], 
                         :my_bills_tracked_facet => [],
                         :my_approved_reps_facet => [],
                         :my_approved_sens_facet => [],
                         :my_disapproved_reps_facet => [],
                         :my_disapproved_sens_facet => [],
                         :public_actions_facet => [],
                         :public_tracking_facet => [],
                         :my_committees_tracked_facet => [],
                         :my_bills_opposed_facet => []}
    facet_results_ff = facets['facet_fields']
    if facet_results_ff && facet_results_ff != []
      
      facet_results_ff.each do |fkey, fvalue|
        facet_results = facet_results_ff[fkey]
      
        #solr running through acts as returns as a Hash, or an array if running through tomcat...hence this stuffs
        facet_results_temp_hash = Hash[*facet_results] unless facet_results.class.to_s == "Hash"
        facet_results_temp_hash = facet_results if facet_results.class.to_s == "Hash"
        logger.info facet_results_temp_hash.to_yaml

        facet_results_temp_hash.each do |key,value|
#          if key == self.ident.to_s && fkey == "my_bills_tracked_facet"
#            my_trackers = value
#          else
            logger.info "#{fkey} - #{key} - #{value}"
            unless facet_results_hsh[fkey.to_sym].length == 5
              object = Person.find_by_id(key) if fkey == "my_people_tracked_facet" || fkey =~ /my_approved_/ || fkey =~ /my_disapproved_/
              object = Subject.find_by_id(key) if fkey == "my_issues_tracked_facet"
              object = Bill.find_by_ident(key) if fkey == "my_bills_tracked_facet" 
              object = Bill.find_by_id(key) if fkey =~ /my_bills_supported/ || fkey =~ /my_bills_opposed/
              facet_results_hsh[fkey.to_sym] << {:object => object, :trackers => value}
            end
#          end
        end
      end      
    else
      return [my_trackers,{}]
    end
    unless facet_results_hsh.empty?
      #sort the hashes
      facet_results_hsh[:my_people_tracked_facet].sort!{|a,b| b[:trackers]<=>a[:trackers] }
      facet_results_hsh[:my_issues_tracked_facet].sort!{|a,b| b[:trackers]<=>a[:trackers] }
      facet_results_hsh[:my_bills_tracked_facet].sort!{|a,b| b[:trackers]<=>a[:trackers] }
      facet_results_hsh[:my_approved_sens_facet].sort!{|a,b| b[:trackers]<=>a[:trackers] }
      facet_results_hsh[:my_bills_opposed_facet].sort!{|a,b| b[:trackers]<=>a[:trackers] }
      facet_results_hsh[:my_bills_supported_facet].sort!{|a,b| b[:trackers]<=>a[:trackers] }
      return [my_trackers, facet_results_hsh]
    else
      return [my_trackers,{}]
    end
  end
  
  def freebase_guid_url
    URI.escape("http://www.freebase.com/api/service/search?query=#{self.name}&type=/common/topic&type=/location/us_state")
  end
  
  def freebase_link
    "http://www.freebase.com/view/en/#{name.downcase.gsub(' ', '_')}"
  end
  
  def freebase_guid
     require 'open-uri'
     require 'json'
     JSON.parse(open(freebase_guid_url).read)['result'].first['article']['id']
  end
  
  def freebase_description_url
    "http://www.freebase.com/api/trans/blurb#{self.freebase_guid}?maxlength=800"
  end
  
  def freebase_description
     require 'open-uri'
     require 'json'
     cache = ActiveSupport::Cache.lookup_store(:mem_cache_store)
     cache.fetch("state_freebase_desc_#{self.id}") {
       open(freebase_description_url).read.gsub(/\/(.)\(help(.)info\)/,'/')
     }
#     JSON.parse(open(freebase_description_url).read)["result"]["guid"]
  end
  
  def image_path
    "public/images/states/#{self.image_name}"
  end
  
  def census_url
    "http://ftp2.census.gov/geo/maps/cong_dist/cd109_gen/st_based/#{self.image_name}"
  end
  
  def image_name
    "cd109_#{abbreviation}.gif"
  end
  
  def self.make_download_script
    State.all.each do |s|
      puts "wget -q '#{s.census_url}'"
    end
  end
  
  def m_thumb_path
    "/images/states/thumbs_250/#{self.image_name}"
  end

  def s_thumb_path
    "/images/states/thumbs_250/#{self.image_name}"
  end

  def party_makeup_graph_url
    size = "330x130"
    colors = "CCCCFF,FFCCCC"
    title = "#{abbreviation}'s%20House%20Party%20Make-up"
    if other_representatives.count == 0
      if republican_representatives.count == 0
        "http://chart.apis.google.com/chart?cht=p&chd=t:#{democrat_representatives.count}&\
chs=#{size}&chl=Democrats (#{democrat_representatives.count})&chds=0,100&chco#{colors}&chtt=#{title}"
      elsif democrat_representatives.count == 0
        "http://chart.apis.google.com/chart?cht=p&chd=t:#{republican_representatives.count}&\
chs=#{size}&chl=Republicans (#{republican_representatives.count})&chds=0,100&chco=#{colors}&chtt=#{title}"
      else
        "http://chart.apis.google.com/chart?cht=p&chd=t:#{democrat_representatives.count},#{republican_representatives.count}&\
chs=#{size}&chl=Democrats (#{democrat_representatives.count})|Republicans (#{republican_representatives.count})&chds=0,100,0,100&chco=#{colors}&chtt=#{title}"

      end        

    else
      "http://chart.apis.google.com/chart?cht=p&chd=t:#{democrat_representatives.count},#{republican_representatives.count},#{other_representatives.count}&\
chs=#{size}&chl=Democrats (#{democrat_representatives.count})|Republicans (#{republican_representatives.count})|Other (#{other_representatives.count})&chds=0,100,0,100,0,100&chco=#{colors}&chtt=#{title}"
    end
  end

  
end
