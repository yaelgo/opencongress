class Admin::HotBillsController < Admin::IndexController
  before_filter :can_blog

  def index
  end
  
  def addbill
    bill = Bill.find_by_id(params[:bill][:id])
    
    if bill
      if params[:bill][:hot_bill_category_id] == 'new'
        unless params[:hot_bill_category][:name].blank?
          c = HotBillCategory.find_or_create_by_name(params[:hot_bill_category][:name])
          c.save
          
          bill.hot_bill_category = c
          
        end
      else
        bill.hot_bill_category_id = params[:bill][:hot_bill_category_id].blank? ? 
                                    nil : params[:bill][:hot_bill_category_id]
      end

      bill.plain_language_summary = params[:bill][:plain_language_summary]
      bill.save
      
      redirect_to :controller => '/bill', :action => 'show', :id => bill.ident
    else
      redirect_to :controller => 'index'
    end
  end
  
end