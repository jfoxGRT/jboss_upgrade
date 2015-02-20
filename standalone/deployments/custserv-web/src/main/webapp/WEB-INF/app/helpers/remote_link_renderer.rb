class RemoteLinkRenderer < WillPaginate::LinkRenderer

  def page_link_or_span(page, span_class = 'current', text = nil)
    text ||= page.to_s
    if(page and page != current_page)
      if(@options[:update_element])
        # Here, params[:action] is always the page that's been loaded; when we merge, params[:action] gets replaced with @options[:params][:action],
        # which is the action used for the Ajax call.
        options = {
          :url => {:params => @template.request.parameters.merge({:page => page,
                                            :action => @options[:action],
                                            :status_indicator => @options[:status_indicator],
                                            :update_element => @options[:update_element]})},
          :update => @options[:update_element],
          :before => (@options[:before_callback].nil?) ? ("Element.show('" + @options[:status_indicator] + "')") : @options[:before_callback],
          :success => (@options[:success_callback].nil?) ? ("Element.hide('" + @options[:status_indicator] + "')") : @options[:success_callback]
        }
        #html_options = {:href => url_for(:params => @template.request.parameters.merge({:page => page, :action => @options[:params][:action]}))}
        @template.link_to_remote(text, options)
      else
        options = {:url => {:params => @template.request.parameters.merge({:page => page, :action => @options[:action]})}}
        @template.link_to_remote(text, options)
      end                         
    else
      @template.content_tag(:span, text, :class => span_class)
    end
  end
end