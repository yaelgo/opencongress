class CommentsController < ApplicationController
  skip_before_filter :store_location
  before_filter :login_required, :only => ["flag", "censor", "ban_ip"]
  before_filter :admin_login_required, :only => ["censor", "ban_ip"]



  def add_comment
    object = Object.const_get(params[:type]).find_by_id(params[:id])
    login_required unless object.class.to_s == "Article"
    if object
      @comment = Comment.new(params[:comment])
      
      @comment.commentable_id = object.id
      @comment.commentable_type = object.class.to_s

      @comment.user_id = current_user.id if logged_in?
      @comment.ip_address = request.remote_ip

      parent = nil
      unless params[:comment][:parent_id].blank?
        parent = Comment.find_by_id(params[:comment][:parent_id])
        @comment.root_id = parent.root_id
      end
        
      dup = Comment.find(:first, :conditions => ["commentable_type = ? AND comment = ? AND commentable_id = ?", object.class.to_s,@comment.comment,object.id])
      if dup
        flash[:notice] = "Duplicate Comment"
        render :partial => "shared/comments3", :locals => {:object => object}
        return
      end 

      if logged_in? 
        unless @comment.save
          flash[:error] = "Failed to save."
          if parent
            render :partial => "shared/comment_form_recursive", :locals => {:parent_id => parent.id, :object => object }
          else
            render :partial => "shared/comments3", :locals => {:object => object}
          end
          return
        else
          if params[:redirect] == 'false'
            render :update do |page|
              page.replace_html "small_comment", "Your comment has been saved<br />" + link_to("View it Now", @comment.commentable_link.merge(:action => "comments", :comment_page => @comment.page), :class => 'jump_to_comment')
            end
            return
          end
          flash[:notice] = "Your comment has been saved."
        end
      else
        unless @comment.save_with_captcha
          flash[:error] = "Failed to save."
          if parent
            render :partial => "shared/comment_form_recursive", :locals => {:parent_id => parent.id, :object => object } 
          else
            render :partial => "shared/comments3", :locals => {:object => object}
          end
          return
        else
          flash[:notice] = "Your comment has been saved."
        end
      end

      # if this is a reply, make it a child, otherwise, make it a parent
      if parent
        if parent.children.empty?
          @comment.move_to_child_of parent
        else
          # normally, we just would do: @comment.move_to_child_of parent
          # but move_to_child_of adds to the left of siblings, and we want the right
          @comment.move_to_right_of parent.children.last
        end
        
        # if this is a reply to a comment, just render the new comment
        render :partial => 'shared/comments_recursive', :locals => {:object => object, :comment => @comment, :myscores => Array.new}
      else
        @comment.update_attribute('root_id', @comment.id)
        
        #params[:comment_page] = @comment.page
#        goto_comment @comment.id, object
        @ajax_comment = true
        
        if @comment.commentable_type == "Article"
           render :update do |page|
             page.redirect_to @comment.commentable_link.merge(:comment_page => @comment.page)
           end
        elsif @comment.commentable_type == "BillTextNode"
          params[:comment_page] = @comment.page
          @goto_comment = @comment
          @comment = nil
          render :partial => "shared/comments3", :locals => {:object => object, :master_container => "bill_text_comments_#{object.nid}"}
        else
#        render :partial => "shared/comments3", :locals => {:object => object}
         render :update do |page|
           page.redirect_to @comment.commentable_link.merge(:action => "comments", :comment_page => @comment.page)
         end
       end
      end      
    else
      flash[:warning] = "Huh?...Logged"
      redirect_to '/' 
    end
  end
  def showcomfield
    object = Object.const_get(params[:type]).find_by_id(params[:object])
    render :partial => "shared/comment_form_recursive", :locals => {:parent_id => params[:parent_id], :object => object } 
  end
  def rate
    comment = Comment.find_by_id(params[:id])
    score = current_user.comment_scores.find_or_create_by_comment_id(comment.id)
    score.score = params[:value]
    score.save
    if comment.comment_scores.length >= 6
      comment.average_rating = comment.comment_scores.average(:score)
      comment.save
    end
    logger.info params.to_yaml
    render :text =>  "<font color='red'>Your rating has been saved.</font>"
  end
  def filter_by_rating
    redirect_to '/' and return unless params[:type]
    page = 1 unless params[:comment_page].to_i > 1
    page = params[:comment_page].to_i unless page
    object = Object.const_get(params[:type]).find_by_id(params[:id])
    if object
      if params[:comment_sort] == 'rating' 
        comments = object.comments.paginate(:page => page, :include => [:comment_scores, :user], :order => "comments.average_rating DESC" )
      elsif params[:comment_sort] == 'newest'
        comments = object.comments.paginate(:page => page, :include => [:comment_scores, :user], :order => "comments.created_at DESC" ) 
      else
        comments = object.comments.paginate(:page => page, :include => [:comment_scores, :user], :order => "comments.root_id ASC, comments.lft ASC" ) 
      end
      @comments = comments.select{|p| p.average_rating < params[:value].to_f}
      # object.comments.find(:all, :conditions => ["average_rating < ?", params[:value]])
      @showcomments = comments.select{|p| p.average_rating >= params[:value].to_f}
      #object.comments.find(:all, :conditions => ["average_rating >= ?", params[:value]])
    end 
  end
  def censor
    comment = Comment.find_by_id(params[:id])

    if params[:commit] == "Censor+BanIP"
      if comment && !comment.ip_address.blank? && comment.ip_address !=~ /^127./
        noob = ApacheBan.create_by_ip(comment.ip_address)
        flash[:notice] = "IP #{comment.ip_address} banned"
    
      else
        flash[:notice] = "No IP associated with that comment."
      end
    end
    
    comment.update_attribute(:censored, true)
    redirect_back_or_default('/')
  end
  
  def flag
    @comment = Comment.find_by_id(params[:id])
    @comment.update_attribute(:flagged, true)
    redirect_to url_for(@comment.commentable_link.merge({:goto_comment => @comment.id}))
  end
  
  def atom_comments
    @comments = []
    @object_type = params[:object]
    if params[:object] == 'bill'
      @object = Bill.find_by_id(params[:id])
      @title = "Comments on #{@object.title_full_common}"
    elsif params[:object] == 'person'
      @object = Person.find_by_id(params[:id])
      @title = "Comments on #{@object.name}"
    end
    
    if @object
      @comments = @object.comments.find(:all, :limit => 20)
    end
    
    render :layout => false
  end
  
  def bill_text_comments
    return if params[:version].blank? or params[:nid].blank?
    
    @comments = []
    btv = BillTextVersion.find_by_id(params[:version])
    btn = btv.bill_text_nodes.find_or_create_by_nid(params[:nid])
    
    render(:partial => 'shared/comments3', :locals => {:object => btn, :master_container => "bill_text_comments_#{params[:nid]}"}) + "</div>"
  end
end
