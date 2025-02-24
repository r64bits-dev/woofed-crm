class Accounts::AttachmentsController < InternalController
  before_action :set_attachment, only: %i[destroy]

  def destroy
    @attachment.destroy
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_attachment
    @attachment = current_user.account.attachments.find(params[:id])
  end
end
