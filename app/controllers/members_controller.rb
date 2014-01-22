class MembersController < ApplicationController
  before_filter :authenticate_member!

  before_filter :set_edit_others
  before_filter :set_edit_roles

  private
  def set_edit_others
    @edit_others = current_member.authorized? "members/edit"
    #should this really be a before_filter?
    return true
  end

  def set_edit_roles
    @edit_roles = current_member.authorized? "members/edit_roles"
    return true
  end


  public 
  def index
    @title = "Member List"
    @order = Member.new.has_attribute?(params[:order]) ? params[:order] : Member::Default_sort_key
    if params[:desc] == "1"
      @order += " DESC" 
      @order_desc = true 
    end

    @members = Member.order(@order)

    respond_to do |format|
      format.html
      format.vcf { render :layout => false }
    end
  end

  def show
    @title = "Member Display"

    @member = Member.find(params[:id])

    respond_to do |format|
      format.html
      format.vcf { render :layout => false }
    end
  end

  def new
    @title = "New Member"

    @member = Member.new
  end

  def create
    @member = Member.new(params[:member])
    if @member.save
      flash[:notice] = 'Member was successfully created.'
      redirect_to members_path
    else
      render :action => 'new'
    end
  end

  def edit_self
    # being used for ACLs

    @title = "Editing Self"
    @member = current_member

    render :action => 'edit'
  end

  def edit
    @title = "Editing Member"
    @member = Member.find(params[:id])
  end

  def update
    if params[:member][:password].blank?
      params[:member].delete(:password)
      params[:member].delete(:password_confirmation)
    end
    
    if(!current_member().authorized?("/members/edit")) #They can only edit themselves
      @member = current_member();
      params[:member].delete('role_ids')
      if (!current_member().authorized?("/accounts/list"))
        params[:member].delete('payrate')
      end
    else #They can edit any member
      @member = Member.find(params[:id])
    end
    if @member.update_attributes(params[:member])
      if @edit_others
        flash[:notice] = 'Member was successfully updated.'
        redirect_to(:action => 'show', :id => @member)
      else
        flash[:notice] = 'Thank you for keeping your information up to date!'
        redirect_to :controller => 'events', :action => 'index'
      end
    else
      render(:action => 'edit')
    end
  end

  def destroy
    Member.find(params[:id]).destroy
    flash[:notice] = 'Member was successfully destroyed.'
    redirect_to members_path
  end
  
  def tshirts
    @title = "T-Shirt Sizes"

    @shirt_sizes = Member.active.group_by(&:shirt_size)
  end
end
