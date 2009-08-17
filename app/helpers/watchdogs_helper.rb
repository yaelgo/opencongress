module WatchdogsHelper

  def url_for_internal(link)
    case link.notebookable.type.to_s
    when 'Bill'
      url_for :controller => 'bill', :action => "show", :id => link.notebookable.ident
    when 'Subject'
      url_for :controller => 'issues', :action => 'show', :id => link.notebookable.to_param      
    when 'Person'
      url_for :controller => 'people', :action => 'show', :id => link.notebookable.to_param
    when 'Commentary'
      link.url
    end    
  end

  def default_title_from_notebookable(notebookable)
    case notebookable.class.to_s
    when 'Bill'
      "OpenCongress: #{notebookable.title_short}"
    when 'Subject'
      "OpenCongress: #{notebookable.term}"
    when 'Person'
      "OpenCongress: #{notebookable.name}"
    when 'Commentary'
      notebookable.title
    end
  end

  def get_label
    @label = ""
    if @type
      case @type
        when 'NotebookFile'
          @label += 'Files '
        when 'NotebookNote'
          @label += 'Notes '
        when 'NotebookLink'
          @label += 'Links '
        when 'NotebookVideo'
          @label += 'Videos '
      end
    else @label += 'All Items '
    end
    if @tag
      @label += "Tagged With '#{@tag}'"
    end
    return @label
  end
      
  def image_for(file, size = '') 
    image_tag("#{BASE_URL}#{file.public_filename(size)}")
  end
  
  def link_to_internal(link)    
    case link.notebookable.type.to_s
    when 'Bill'
      link_to link.title, :controller => 'bill', :action => "show", :id => link.notebookable.ident
    when 'Subject'
      link_to link.title, :controller => 'issues', :action => 'show', :id => link.notebookable.to_param      
    when 'Person'
      link_to  link.title, :controller => 'people', :action => 'show', :id => link.notebookable.to_param
    when 'Commentary'
      link_to link.title, link.url
    end    
  end
  
  def div_height(y)
    ymod = y % 24
    div_y = (24 - ymod) + y
    return div_y
  end

  def is_on(type)
    if @type == type
      "on"
    else
      "off"
    end
  end
  
end
