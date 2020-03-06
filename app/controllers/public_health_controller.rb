class PublicHealthController < ApplicationController
  before_action :authenticate_user!

  def index
    # Restrict access to public health only
    unless current_user.can_view_public_health_dashboard?
      redirect_to root_url and return
    end
    @symptomatic_count = current_user.viewable_patients.symptomatic.count
    @closed_count = current_user.viewable_patients.monitoring_closed.count
    @non_reporting_count = current_user.viewable_patients.non_reporting.count
    @asymptomatic_count = current_user.viewable_patients.asymptomatic.count
    @new_count = current_user.viewable_patients.new_subject.count
  end

  def symptomatic_patients
    # Restrict access to public health only
    unless current_user.can_view_public_health_dashboard?
      redirect_to root_url and return
    end
    data = current_user.viewable_patients.symptomatic

    # Filter on search
    search = params[:search][:value] unless params[:search].nil?
    if search.present?
      filtered = data.where('lower(first_name) like ?', "%#{search.downcase}%").or(
        data.where('lower(last_name) like ?', "%#{search.downcase}%").or(
          data.where('lower(user_defined_id_statelocal) like ?', "%#{search.downcase}%")
        )
      )
    else
      filtered = data
    end

    # Paginate
    length = params[:length].to_i
    page = params[:start].to_i == 0 ? 1 : (params[:start].to_i / length) + 1
    draw = params[:draw].to_i

    render json: { data: filtered.paginate(per_page: length, page: page), draw: draw, recordsTotal: data.count, recordsFiltered: filtered.count }
  end

  def closed_patients
    # Restrict access to public health only
    unless current_user.can_view_public_health_dashboard?
      redirect_to root_url and return
    end
    data = current_user.viewable_patients.monitoring_closed

    # Filter on search
    search = params[:search][:value] unless params[:search].nil?
    if search.present?
      filtered = data.where('lower(first_name) like ?', "%#{search.downcase}%").or(
        data.where('lower(last_name) like ?', "%#{search.downcase}%").or(
          data.where('lower(user_defined_id_statelocal) like ?', "%#{search.downcase}%")
        )
      )
    else
      filtered = data
    end

    # Paginate
    length = params[:length].to_i
    page = params[:start].to_i == 0 ? 1 : (params[:start].to_i / length) + 1
    draw = params[:draw].to_i

    render json: { data: filtered.paginate(per_page: length, page: page), draw: draw, recordsTotal: data.count, recordsFiltered: filtered.count }
  end

  def non_reporting_patients
    # Restrict access to public health only
    unless current_user.can_view_public_health_dashboard?
      redirect_to root_url and return
    end

    data = current_user.viewable_patients.non_reporting

    # Filter on search
    search = params[:search][:value] unless params[:search].nil?
    if search.present?
      filtered = data.where('lower(first_name) like ?', "%#{search.downcase}%").or(
        data.where('lower(last_name) like ?', "%#{search.downcase}%").or(
          data.where('lower(user_defined_id_statelocal) like ?', "%#{search.downcase}%")
        )
      )
    else
      filtered = data
    end

    # Paginate
    length = params[:length].to_i
    page = params[:start].to_i == 0 ? 1 : (params[:start].to_i / length) + 1
    draw = params[:draw].to_i

    render json: { data: filtered.paginate(per_page: length, page: page), draw: draw, recordsTotal: data.count, recordsFiltered: filtered.count }
  end

  def asymptomatic_patients
    # Restrict access to public health only
    unless current_user.can_view_public_health_dashboard?
      redirect_to root_url and return
    end

    data = current_user.viewable_patients.asymptomatic

    # Filter on search
    search = params[:search][:value] unless params[:search].nil?
    if search.present?
      filtered = data.where('lower(first_name) like ?', "%#{search.downcase}%").or(
        data.where('lower(last_name) like ?', "%#{search.downcase}%").or(
          data.where('lower(user_defined_id_statelocal) like ?', "%#{search.downcase}%")
        )
      )
    else
      filtered = data
    end

    # Paginate
    length = params[:length].to_i
    page = params[:start].to_i == 0 ? 1 : (params[:start].to_i / length) + 1
    draw = params[:draw].to_i

    render json: { data: filtered.paginate(per_page: length, page: page), draw: draw, recordsTotal: data.count, recordsFiltered: filtered.count }
  end

end
