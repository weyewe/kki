class SavingsEntriesController < ApplicationController
  def new_voluntary_savings_adjustment
    @office = current_user.active_job_attachment.office
    # @office_members = @office.members
    # @all_communes = @office.all_communes_under_management
  end
end
