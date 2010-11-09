class UsersController < ApplicationController
  respond_to :html,:json
  
  protect_from_forgery :except => [:post_data]
  
  # Don't forget to edit routes if you're using RESTful routing
  # 
  #resources :users,:only => [:index] do
  #   collection do
  #     post "post_data"
  #   end
  # end

  def post_data
    message=""
    user_params = { :id => params[:id],:name => params[:name],:email => params[:email],:position => params[:position] }
    case params[:oper]
    when 'add'
      if params["id"] == "_empty"
        user = User.create(user_params)
        message << ('add ok') if user.errors.empty?
      end
      
    when 'edit'
      user = User.find(params[:id])
      message << ('update ok') if user.update_attributes(user_params)
    when 'del'
      User.destroy_all(:id => params[:id].split(","))
      message <<  ('del ok')
    when 'sort'
      users = User.all
      users.each do |user|
        user.position = params['ids'].index(user.id.to_s) + 1 if params['ids'].index(user.id.to_s) 
        user.save
      end
      message << "sort ak"
    else
      message <<  ('unknown action')
    end
    
    unless (user && user.errors).blank?  
      user.errors.entries.each do |error|
        message << "<strong>#{User.human_attribute_name(error[0])}</strong> : #{error[1]}<br/>"
      end
      render :json =>[false,message]
    else
      render :json => [true,message] 
    end
  end
  
  
  def index
    index_columns ||= [:id,:name,:email,:position]
    current_page = params[:page] ? params[:page].to_i : 1
    rows_per_page = params[:rows] ? params[:rows].to_i : 10

    conditions={:page => current_page, :per_page => rows_per_page}
    conditions[:order] = params["sidx"] + " " + params["sord"] unless (params[:sidx].blank? || params[:sord].blank?)
    
    if params[:_search] == "true"
      conditions[:conditions]=filter_by_conditions(index_columns)
    end
    
    @users=User.paginate(conditions)
    total_entries=@users.total_entries
    
    respond_with(@users) do |format|
      format.json { render :json => @users.to_jqgrid_json(index_columns, current_page, rows_per_page, total_entries)}  
    end
  end

end