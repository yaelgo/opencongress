# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include SimpleCaptcha::ControllerHelpers
  
  before_filter :store_location, :except => ["rescue_action_in_public"]
  before_filter :show_comments?
  before_filter :current_tab
  before_filter :has_accepted_tos?
  before_filter :get_site_text_page

  def paginate_collection(collection, options = {})
    # from http://www.bigbold.com/snippets/posts/show/389
    options[:page] = options[:page] || params[:page] || 1
    default_options = {:per_page => 10, :page => 1}
    options = default_options.merge options
    
    pages = Paginator.new self, collection.size, options[:per_page], options[:page]
    first = pages.current.offset
    last = [first + options[:per_page], collection.size].min
    slice = collection[first...last]
    return [pages, slice]
  end

  # this is only used for search results
  # CLEANUP TASK: combine this and the above pagintor
  def pages_for(size, options = {})
    default_options = {:per_page => DEFAULT_SEARCH_PAGE_SIZE }
    options = default_options.merge options
    pages = Paginator.new self, size, options[:per_page], (params[:page]||1)
    pages
  end
  
  def is_valid_email?(e, with_headers = false)
    if with_headers == false
      email_check = Regexp.new('^[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$')
    else
      email_check = Regexp.new('[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]')
    end

    if (e =~ email_check) == nil
      false
    else
      true
    end		
  end
  
  def days_from_params(days)
    days = days.to_i if (days && !days.kind_of?(Integer))
    return (days && ((days == 7) || (days == 14) || (days == 30))) ? days.days : DEFAULT_COUNT_TIME
  end
  
  def rescue_action_in_public(exception)
    case exception
    when ::ActionController::RoutingError, ::ActionController::UnknownAction then
      render :partial => "index/notfound_page", :layout => 'application', :status => "404"
    else
      render :partial => "index/error_page", :layout => 'application', :locals => { :exception => exception }, :status => "500"
    end
  end
  
  def comment_redirect(comment_id)
    comment = Comment.find_by_id(comment_id)
    logger.info "COMMENT_ID:#{comment_id}"
    logger.info "PAGE: #{comment.page}"
    if comment.commentable_type == "Article"
      redirect_to comment.commentable_link.merge(:comment_page => comment.page)
    else
      redirect_to comment.commentable_link.merge(:action => "comments", :comment_page => comment.page, :comment_id => comment_id)
    end
    @goto_comment = comment
  end

  
  def goto_comment(comment_id, commentable)
    @goto_comment = Comment.find_by_id(comment_id)
    if @goto_comment
      #commentable.comments.find(:all, :order => 'comments.root_id ASC, comments.lft ASC').select{|c| c == @goto_comment }.each{|cc| logger.info "MATCHING COMMENT: #{cc.id} id, #{cc.lft} lft, #{cc.comment}"}
      index = commentable.comments.find(:all, :order => 'comments.root_id ASC, comments.lft ASC').rindex(@goto_comment)
      if index
        comm_controller = ""
        comm_action = "comments"
        case @goto_comment.commentable_type.to_s
          when 'Person'
            comm_controller = "people"
          when 'Subject'
            comm_controller = "issue"
          when 'Bill'
            comm_controller = "bill"
          when 'Article'
            comm_controller = "articles"
            comm_action = "show"
        end
        redirect_to :controller => comm_controller, :action => comm_action, :comment_page => ((index.to_f + 1.0 / Comment.per_page.to_f) + 1.to_f).floor, :comment_id => comment_id
#        @current_tab = 'comments'
#        params[:comment_page] = ((index.to_f / Comment.per_page.to_f) + 1.to_f).floor
      else
        @goto_comment = nil
      end
    end
    
    params[:goto_comment] = nil
  end
  
  private
  
  def has_accepted_tos?
    if logged_in?
      logger.info "USER APP TOS: #{current_user.accepted_tos}"
      unless current_user.accepted_tos == true
        redirect_to :controller => "/account", :action => "accept_tos"
      end
    end
  end
  
  def current_tab
    @current_tab = params[:navtab].blank? ? nil : params[:navtab]
  end
  def show_comments?
      if params[:show_comments] == "1"
        @show_comments = true
      end
  end
  def admin_login_required
    if !(logged_in? && current_user.user_role.can_administer_users)
      redirect_to :controller => '/admin', :action => 'index'
    end
  end
  def can_text
    if !(logged_in? && current_user.user_role.can_manage_text)
      redirect_to :controller => '/admin', :action => 'index'
    end
  end
  def can_moderate
    if !(logged_in? && current_user.user_role.can_moderate_articles)
      redirect_to :controller => '/admin', :action => 'index'
    end
  end
  def can_blog
    unless (logged_in? && current_user.user_role.can_blog)
      redirect_to :controller => "/admin", :action => "index"
    end
  end
  def can_stats
    unless (logged_in? && current_user.user_role.can_see_stats)
      redirect_to :controller => "/admin", :action => "index"
    end
  end
  def no_users
    unless (logged_in? && current_user.user_role.name != "User")
      flash[:notice] = "Permission Denied"
      redirect_to :controller => "/account", :action => "login"
    end
  end
  
  def prepare_tsearch_query(text)
    text = text.strip
    
    # remove non alphanumeric 
    text = text.gsub(/[^\w\.\s\-_]+/, "")
    
    # replace multiple spaces with one space 
    text = text.gsub(/\s+/, " ")
    
    # replace spaces with '&'
    text = text.gsub(/ /, "&")
    
    text
  end

  def site_text_params_string(prms)
    ['controller', 'action', 'id', 'person_type', 'commentary_type'].collect{|k|"#{k}=#{prms[k]}" }.join("&")
  end
  
  def get_site_text_page
    page_params = site_text_params_string(params)
    
    @site_text_page = SiteTextPage.find_by_page_params(page_params)
    @site_text_page = OpenStruct.new if @site_text_page.nil?
  end
  
  protected
  def dump_session
    logger.info session.to_yaml
  end
  
  def log_error(exception) #:doc:
    if ActionView::TemplateError === exception
      logger.fatal(exception.to_s)
    else
      logger.fatal(
        "\n\n[#{Time.now.to_s}] #{exception.class} (#{exception.message}):\n    " + 
        clean_backtrace(exception).join("\n    ") + 
        "\n\n"
      )
    end
  end
end
