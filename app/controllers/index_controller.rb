class IndexController < ApplicationController
  layout "frontpage"
    
  def index
    unless read_fragment("frontpage_bill_mostviewed")
      @popular_bills = PageView.popular('Bill', DEFAULT_COUNT_TIME, 6) || Bill.find(:first)
    end
    unless read_fragment("frontpage_bill_newest")
      @newest_bills = Bill.find(:all, :order => 'introduced DESC', :limit => 6)
    end
    unless read_fragment("frontpage_issue_mostviewed")
      @popular_issues = PageView.popular('Subject', DEFAULT_COUNT_TIME, 6) || Issue.find(:first)
    end
    unless read_fragment("frontpage_person_topsenators")
      @popular_senators = Person.list_chamber('sen', DEFAULT_CONGRESS, "view_count desc", 6)
    end
    unless read_fragment("frontpage_person_topreps")
      @popular_reps = Person.list_chamber('rep', DEFAULT_CONGRESS, "view_count desc", 6)
    end
    unless read_fragment("frontpage_top_searches")
      @hot_bills = PageView.popular('Bill', DEFAULT_COUNT_TIME, 6, DEFAULT_CONGRESS, true) || Bill.find(:first)
      
    end
    unless read_fragment("frontpage_featured_senator")    
      @popular_sen_text = FeaturedPerson.senator
    end
    unless read_fragment("frontpage_featured_representative")    
      @popular_rep_text = FeaturedPerson.representative
    end
    
    @sessions = CongressSession.sessions
  end
  
  def notfound
    render :partial => "index/notfound_page", :layout => 'application', :status => "404"
  end
  
  def about
    redirect_to :controller => "about"
  end

	def popular
		render :update do |page|
			page.replace_html 'popular', :partial => "index/popular", :locals => {:object => @object}
		end
	end
end
