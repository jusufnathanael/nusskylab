# UsersController: manage actions related to user
#   index:      list of users
#   new:        view to create a user
#   create:     create a user
#   preview_as: for admin to login as another user
#   edit:       view to update a user
#   update:     update a user
#   destroy:    delete a user
class UsersController < ApplicationController
  def index
    !authenticate_user(true, true) && return
    @page_title = t('.page_title')
    @users = User.order(:user_name).all
  end

  def new
    !authenticate_user(true, true) && return
    @page_title = t('.page_title')
    @user = User.new
  end

  def create
    !authenticate_user(true, true) && return
    @user = User.new(user_params(true))
    if @user.save
      redirect_to users_path, flash: {
        success: t('.success_message')
      }
    else
      redirect_to new_user_path, flash: {
        danger: t('.failure_message',
                  error_message: @user.errors.full_messages.join(', '))
      }
    end
  end

  def preview_as
    !authenticate_user(true, true) && return
    user = User.find(params[:id]) || (record_not_found && return)
    sign_out(current_user)
    sign_in(user)
    redirect_to user_path(user.id)
  end

  def register_as_student
    @user = User.find(params[:id])
    !authenticate_user(true, false, [@user]) && return
    milestone = Milestone.find_by(name: 'Milestone 1', cohort: current_cohort)
    survey_template = SurveyTemplate.find_by(
      milestone_id: milestone.id,
      survey_type: SurveyTemplate.survey_types[:survey_type_registration])
    registration = Registration.find_by(
      survey_template_id: survey_template.id, user_id: @user.id) ||
                   Registration.new(survey_template_id: survey_template.id,
                                    user_id: @user.id)
    @page_title = t('.page_title')
    render locals: {
      survey_template: survey_template,
      questions: survey_template.questions.order('questions.id ASC'),
      registration: registration
    }
  end

  def register
    @user = User.find(params[:id])
    !authenticate_user(true, false, [@user]) && return
    milestone = Milestone.find_by(name: 'Milestone 1', cohort: current_cohort)
    survey_template = SurveyTemplate.find_by(
      milestone_id: milestone.id,
      survey_type: SurveyTemplate.survey_types[:survey_type_registration])
    registration = Registration.find_by(
      survey_template_id: survey_template.id, user_id: @user.id) ||
                   Registration.new(survey_template_id: survey_template.id,
                                    user_id: @user.id)
    registration.response_content = registration_params.to_json
    registration.save
    student = Student.student?(@user.id, cohort: current_cohort) ||
              Student.new(user_id: @user.id, cohort: current_cohort,
                          is_pending: true)
    student.save
    redirect_to user_path(@user.id)
  end

  def register_as_team
    @user = User.find(params[:id])
    !authenticate_user(true, false, [@user]) && return
    student = Student.student?(@user.id, cohort: current_cohort)
    return redirect_to user_path(@user.id), flash: {
      danger: t('.register_as_student_message')
    } unless student
    return redirect_to student_path(student) unless student.is_pending
    student_team = student.team || Team.new
    @page_title = t('.page_title')
    render locals: {
      student: student,
      student_team: student_team
    }
  end

  def register_team
    @user = User.find(params[:id])
    !authenticate_user(true, false, [@user]) && return
    team_params = params.require(:team).permit(:email)
    user = User.find_by(email: team_params[:email])
    return redirect_to user_path(@user.id), flash: {
      danger: t('.no_user_found_message')
    } unless user
    student = Student.student?(user.id, cohort: current_cohort)
    return redirect_to user_path(@user.id), flash: {
      danger: t('.no_registered_student_found_message')
    } if !student || !student.is_pending
    return redirect_to user_path(@user.id), flash: {
      danger: t('.student_found_team_message')
    } if student.team
    student_user = Student.student?(@user.id, cohort: current_cohort)
    return redirect_to user_path(@user.id), flash: {
      danger: t('.cannot_register_team_message')
    } if !student_user || !student_user.is_pending || student_user.team
    team = Team.new(
      team_name: (Team.order('id').last.id + 1), is_pending: true,
      cohort: current_cohort, invitor_student_id: student_user.id)
    team.save
    student.team_id = team.id
    student.save
    student_user.team_id = team.id
    student_user.save
    redirect_to user_path(@user.id), flash: {
      success: t('.team_invitation_success_message')
    }
  end

  def confirm_team
    @user = User.find(params[:id])
    !authenticate_user(true, false, [@user]) && return
    team_params = params.require(:team).permit(:confirm)
    student_user = Student.student?(@user.id, cohort: current_cohort)
    return redirect_to user_path(@user.id), flash: {
      danger: t('.cannot_confirm_team_message')
    } if !student_user || !student_user.is_pending || !student_user.team
    team = student_user.team
    if team_params[:confirm] == 'true'
      team.is_pending = false
      team.save
      flash_message = t('.team_invitation_accepted_message')
    else
      team.destroy
      flash_message = t('.team_invitation_rejected_message')
    end
    redirect_to user_path(@user.id), flash: {
      success: flash_message
    }
  end

  def show
    @user = User.find(params[:id]) || (record_not_found && return)
    !authenticate_user(true, false, [@user]) && return
    @page_title = t('.page_title', user_name: @user.user_name)
  end

  def edit
    @user = User.find(params[:id]) || (record_not_found && return)
    !authenticate_user(true, false, [@user]) && return
    @page_title = t('.page_title', user_name: @user.user_name)
  end

  def update
    @user = User.find(params[:id]) || (record_not_found && return)
    !authenticate_user(true, false, [@user]) && return
    user_ps = user_params
    user_ps.except!(:provider)
    if @user.update(user_ps)
      redirect_to @user, flash: {
        success: t('.success_message')
      }
    else
      redirect_to @user, flash: {
        danger: t('.failure_message',
                  error_message: @user.errors.full_messages.join(', '))
      }
    end
  end

  def destroy
    !authenticate_user(true, true) && return
    @user = User.find(params[:id])
    redirect_to users_path, flash: {
      success: t('.success_message')
    }
  end

  private

  def user_params(generate_pswd = false)
    user_ps = params.require(:user).permit(
      :user_name, :email, :uid, :provider, :github_link, :linkedin_link,
      :blog_link, :program_of_study, :self_introduction)
    user_ps[:password] = Devise.friendly_token.first(8) if generate_pswd
    user_ps[:provider] = user_ps[:provider].to_i
    user_ps[:program_of_study] = user_ps[:program_of_study].to_i
    user_ps
  end

  def registration_params
    params.require(:questions).permit!
  end
end
