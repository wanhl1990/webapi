class UsersController < ApplicationController

#  before_action :require_login
  
  def index
    #render json: User.all
#    session[:id] = 123
    @user = User.all
  end

  def create

    if !current_user_is_admin?
      api_err 20005, 'Current user can not create user.'
    end

    @user = User.new(create_params)

    #@user.save
    # @user.save || api_err(20004, 'user create error')
    # api_err(20004, 'user create error') unless @user.save
    if !@user.save
      api_err 20004, 'user create error'
    end
  end

  def destroy
    c_user = User.find_by(username: params[:current_user])
    if !c_user 
      api_err 20007, 'Current user not found.'
    end

    if c_user.role_id != 2
      api_err 20007, 'Current user can not delete user.'
    end

    user = User.find_by(id: params[:id])
    if !user 
      api_err 86, "User does not exist'"
    elsif !user.destroy  # Use else if . Or .destroy method will not found by nil class.
      api_err 20006, "delete user error"
    end
  end

  def show
#   logger.info("sessin is #{session[:id]}")
    @user = User.find_by(id: params[:id])
    if !@user
      api_err 86, "User does not exist"
    end
#    render json: @user
  end

  def update
    @user =  user_can_change_info? 
    if !@user
      api_err 20002, "User info only can be changed by self or admin user"
      return 
    elsif !@user.update_attributes(update_params)
      api_err 20003, "User info update error!"
      return
    end
  end

  def modify_password
#    logger.info("user: #{params[:username]}")
    logger.info("cookie #{response.headers}")
    @user = User.find_by(username: params[:username])
    if !@user
      api_err(86, 'User does not exist')
      return
    end

    if @user.password != params[:old_password]
      #logger.info("para: #{params[:old_password]}, user:")
      api_err 147, 'Old password is wrong'
      return
    end

    @user.password = params[:new_password]
    begin 
      @user.save
    rescue e
      logger.error('#{e}')
    end
  end

  private

  def create_params
    params.require(:user).permit(:username, :password, :email, :phone_no, :description, :role_id)
  end

  def update_params
    params.require(:user).permit(:password, :email, :phone_no, :description,:role_id)
  end

  def get_user
    user = User.find_by(id:params[:id])

    if !user
      api_err 86, "User does not exist"
    else
      user
    end
  end

  # Check the user can change the info or not.
  # if the user which to change is not the user which login now, or 
  # the user logined is not the  user adminastrator. It return false.
  def user_can_change_info?
    @user_to_modify = User.find_by(id:params[:id])
    @user_now  = User.find_by(username: params[:current_user])

    if !@user_now
      return false
    end

    if (@user_to_modify.username != params[:current_user]) && (@user_now.role_id != 2)
      false
    else
      @user_to_modify
    end
  end

  def current_user_is_admin?
    user = User.find_by(username: params[:current_user])

    return false if (!user || user.role_id != 2)

    true
  end
end
