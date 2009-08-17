class RollCallController < ApplicationController
  helper :index
  skip_before_filter :store_location, :except => [:show, :all]
  before_filter :page_view, :only => :show
  before_filter :login_required, :only => [:make_hot]
  before_filter :no_users, :only => [:can_blog]
  
  @@VOTE_TYPES = { "+" => "Aye", "-" => "Nay", "0" => "Abstain" }
  @@VOTE_VALS = { "Aye" => "+", "Nay" => "-", "Abstain" => "0" }
  
  def master_piechart_data
    @roll_call = RollCall.find_by_id(params[:id])
    
    colors = []
    vals = []
    
    if @roll_call.ayes > 0
      vals << OFC2::PieValue.new(:value => @roll_call.ayes, :label => "Aye (#{@roll_call.ayes})", :on_click => 'openRollCallOverlay("Aye_All")')
      colors << "#4ED046"
    end
    
    if @roll_call.nays > 0
      vals << OFC2::PieValue.new(:value => @roll_call.nays, :label => "Nay (#{@roll_call.nays})", :on_click => 'openRollCallOverlay("Nay_All")')
      colors << "#F53C34"
    end
    
    if @roll_call.abstains > 0
      vals << OFC2::PieValue.new(:value => @roll_call.abstains, :label => "Abstained (#{@roll_call.abstains})", :on_click => 'openRollCallOverlay("Abstain_All")')
      colors << "#BDBDBD"
    end
    
    pie = OFC2::Pie.new(
      :no_labels => true,
      :gradient_fill => false,
      :alpha => 0.8,
      :start_angle => 270,
      :animate =>  [OFC2::PieFade.new, OFC2::PieBounce.new],
      :tip => "#label#\n(Click for Details)",
      :values => vals,
      :radius => 80
    )
    pie_shadow = OFC2::Pie.new(
      :no_labels => true,
      :gradient_fill => false,
      :alpha => 0.5,
      :shadow => true,
      :start_angle => 270,
      #:animate =>  [OFC2::PieFade.new, OFC2::PieBounce.new],
      :tip => "#label#\n(Click for Details)",
      :values => vals,
      :radius => 80
    )
    pie.colours = colors
    chart = OFC2::Graph.new
    chart.title= OFC2::Title.new( :text => "#{@roll_call.chamber.capitalize} Roll Call ##{@roll_call.number}" , :style => "{font-size: 14px; color: #b50F0F; text-align: center;}")
    chart << pie_shadow
    chart << pie      
    chart.bg_colour = '#FFFFFF'

    render :text => chart.render
  end
  
  def partyvote_piechart_data
    @roll_call = RollCall.find_by_id(params[:id])
    radius = params[:radius] ||= 80
    votes = @roll_call.roll_call_votes.select { |rcv| rcv.vote == params[:breakdown_type] }
  
    disclaimer_note = params[:disclaimer_off].blank? ? "**" : ""
    
    democrat_votes = votes.select { |rcv| rcv.person.party == 'Democrat' if rcv.person }
    republican_votes = votes.select { |rcv| rcv.person.party == 'Republican' if rcv.person }
    other_votes_size = votes.size - democrat_votes.size - republican_votes.size
    
    vals = []
    colors = []
    
    if republican_votes.size > 0
      vals << OFC2::PieValue.new(:value => republican_votes.size, :label => "Republican (#{republican_votes.size})", :on_click => "openRollCallOverlay('Republican_#{@@VOTE_TYPES[params[:breakdown_type]]}')")
      colors << "#F84835"
    end
    
    if democrat_votes.size > 0
      vals << OFC2::PieValue.new(:value => democrat_votes.size, :label => "Democrat (#{democrat_votes.size})", :on_click => "openRollCallOverlay('Democrat_#{@@VOTE_TYPES[params[:breakdown_type]]}')")
      colors << "#5D77DA"
    end
    
    if other_votes_size > 0
      vals << OFC2::PieValue.new(:value => other_votes_size, :label =>"Other (#{other_votes_size})", :on_click => "openRollCallOverlay('Other_#{@@VOTE_TYPES[params[:breakdown_type]]}')")
      colors << "#DDDDDD"
    end
    
     pie = OFC2::Pie.new(
      :no_labels => true,
      :gradient_fill => false,
      :alpha => 0.8,
      :start_angle => 270,
      :animate =>  [OFC2::PieFade.new, OFC2::PieBounce.new],
      :tip => "#label#\n(Click for Details)",
      :values => vals,
      :radius => radius
    )
    pie_shadow = OFC2::Pie.new(
      :no_labels => true,
      :gradient_fill => false,
      :alpha => 0.5,
      :shadow => true,
      :start_angle => 270,
      :animate =>  [OFC2::PieFade.new, OFC2::PieBounce.new],
      :tip => "#label#\n(Click for Details)",
      :values => vals,
      :radius => radius
    )
    pie.colours = colors
    chart = OFC2::Graph.new
    chart.title = OFC2::Title.new(:text => "#{@@VOTE_TYPES[params[:breakdown_type]]} Votes: #{votes.size}#{disclaimer_note}", :style => "font-size:14px;color:#333;")
    chart << pie_shadow
    chart << pie
    chart.bg_colour = '#FFFFFF'

    render :text => chart.render

  end
  
  def show
    @roll_call = RollCall.find_by_id(params[:id])
    
    unless @roll_call
      redirect_to :controller => 'index', :action => 'notfound'
      return
    end
    @master_chart = ofc2(400,220, "roll_call/master_piechart_data/#{@roll_call.id}")
    @aye_chart = ofc2(400,220, "roll_call/partyvote_piechart_data/#{@roll_call.id}?breakdown_type=#{CGI.escape("+")}")
    @nay_chart = ofc2(400,220, "roll_call/partyvote_piechart_data/#{@roll_call.id}?breakdown_type=-")
    @abstain_chart = ofc2(400,220, "roll_call/partyvote_piechart_data/#{@roll_call.id}?breakdown_type=0")


    @page_title = "#{@roll_call.chamber} Roll Call ##{@roll_call.number} Details"
    @title_desc = SiteText.find_title_desc('roll_call_show')
    
    @breadcrumb = { 
      1 => { 'text' => "Roll Calls", 'url' => { :controller => 'roll_call'} }
    }
    if @roll_call.bill
      @breadcrumb = {
        2 => { 'text' => @roll_call.roll_type + ": " + @roll_call.bill.title_typenumber_only, 
               'url' => { :controller => 'roll_call', :action => 'show', :id => @roll_call} }
      }
    else
      @breadcrumb = {
         2 => { 'text' => @roll_call.question, 
                'url' => { :controller => 'roll_call', :action => 'show', :id => @roll_call} }
      }
    end
  end
  
  def make_hot
    @roll_call = RollCall.find_by_id(params[:id])
    @roll_call.is_hot = true
    @roll_call.hot_date = Time.now
    @roll_call.title = params[:roll_call][:title] if params[:roll_call][:title]
    @roll_call.save
    redirect_back_or_default("/roll_call/show/#{@roll_call.id}")
  end
  
  def sublist
    @roll_call = RollCall.find(params[:id])
    @learn_off = true
    
    if params[:vote] == 'Aye'
      @vote = 'Aye'
    elsif params[:vote] == 'Nay'
      @vote = 'Nay'
    else
      @vote = 'Abstain'
    end

    if params[:party] == 'Democrat'
      @party = 'Democrat'
    elsif params[:party] == 'Republican'
      @party = 'Republican'
    else
      @party = 'Other'
    end
    
    type_votes = @roll_call.roll_call_votes.select { |rcv| rcv.vote == @@VOTE_VALS[@vote] }
    @votes = type_votes.select { |rcv| rcv.person.party == @party if rcv.person }

    @page_title = "#{@roll_call.chamber} Roll Call ##{@roll_call.number}: #{@party}s Voting '#{@vote}'"
    @title_desc = SiteText.find_title_desc('roll_call_show')
  end
  
  def index
    redirect_to :action => 'all'
    @learn_off = true
  end
  
  def all
    @page = params[:page].blank? ? 1 : params[:page]
    
    if params[:sort] == 'hotbills'
      @sort = 'hotbills'
      @rolls = RollCall.find(:all, :include => :bill, :order => 'roll_calls.date DESC',
                             :conditions => ['roll_calls.date > ? AND bills.hot_bill_category_id IS NOT NULL', 
                                            CONGRESS_START_DATES[DEFAULT_CONGRESS]]).paginate :page => @page

    elsif params[:sort] == 'oldest'
      @sort = 'oldest'
      @rolls = RollCall.find(:all, :order => 'date ASC', 
                             :conditions => ['date > ?', CONGRESS_START_DATES[DEFAULT_CONGRESS]]).paginate :page => @page

    else
      @sort = 'newest'
      @rolls = RollCall.find(:all, :order => 'date DESC', 
                             :conditions => ['date > ?', CONGRESS_START_DATES[DEFAULT_CONGRESS]]).paginate :page => @page

    end
    @carousel = [PageView.popular('RollCall', DEFAULT_COUNT_TIME).slice(0..9)] 
    @page_title = 'All Roll Calls'
    @title_desc = SiteText.find_title_desc('roll_call_all')
    
    @breadcrumb = { 
      1 => { 'text' => "Roll Calls", 'url' => { :controller => 'roll_call'} },
      2 => { 'text' => "All", 'url' => { :controller => 'roll_call', :action => 'all'} }
    }   
    @atom = {'link' => url_for(:only_path => false, :controller => 'roll_call', :action => 'atom'), 'title' => "Recent Roll Calls"}
  end
  
  def search
    @roll_query = params[:q]
    
    query_stripped = prepare_tsearch_query(@roll_query)
    
    @rolls = RollCall.find_by_sql(
                ["SELECT roll_calls.* FROM roll_calls, bills, bill_fulltext
                               WHERE bills.session=? AND
                                     bill_fulltext.fti_names @@ to_tsquery('english', ?) AND
                                     bills.id = bill_fulltext.bill_id AND 
                                     roll_calls.bill_id=bills.id
                               ORDER BY bills.hot_bill_category_id, roll_calls.date DESC", DEFAULT_CONGRESS, query_stripped]
                              )
                               
     render :partial => 'roll_calls_list', :locals => { :rolls => @rolls }, :layout => false
  end
  
  def atom
    @rolls = RollCall.find :all, :order => 'date DESC', :limit => 20
    expires_in 60.minutes, :private => false

    render :layout => false
  end
  
  def compare_two_rolls
    @roll_call1 = RollCall.find_by_ident(params[:vote1])  
    @roll_call2 = RollCall.find_by_ident(params[:vote2])  
    
    unless @roll_call1.where == @roll_call2.where
      flash[:error] = "Can't compare roll calls in different chambers!"
      redirect_to :action => 'index'
      return
    end
    
    first_vote_condition = params[:first_vote].nil? ? "" : " AND roll_call1.vote = '#{@@VOTE_VALS[params[:first_vote]]}' "
    
    @people = Person.find_by_sql(["SELECT people.*, roll_call1.vote as vote1, roll_call2.vote as vote2
                                  FROM people 
                                  INNER JOIN 
                                    (SELECT roll_call_votes.* FROM roll_call_votes 
                                     WHERE roll_call_votes.roll_call_id = ?) roll_call1 ON roll_call1.person_id = people.id 
                                  INNER JOIN 
                                    (SELECT roll_call_votes.* FROM roll_call_votes 
                                     WHERE roll_call_votes.roll_call_id = ?) roll_call2 ON roll_call2.person_id = people.id
                                  WHERE roll_call1.vote <> roll_call2.vote #{first_vote_condition}
                                  ORDER BY people.lastname",
                                 @roll_call1.id, @roll_call2.id])
    @page_title = "Comparing #{@roll_call1.where.capitalize} Vote ##{@roll_call1.number} to ##{@roll_call2.number}"
  end
  
  def summary_text
    @roll_call = RollCall.find_by_ident(params[:id])  
    
    render :layout => false
  end
  
  private

  def page_view
    @roll_call = RollCall.find(params[:id])
    
    if @roll_call
      PageView.create_by_hour(@roll_call, request)
    end
  end
  
end
