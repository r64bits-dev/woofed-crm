class Accounts::DealsController < InternalController
  include ProductConcern

  before_action :set_deal,
                only: %i[show edit update destroy events_to_do events_done deal_products deal_assignees]
  before_action :set_deal_product, only: %i[edit_product
                                            update_product]

  # GET /deals or /deals.json
  def index
    @deals = current_user.account.deals
  end

  # GET /deals/1 or /deals/1.json
  def show; end

  # GET /deals/new
  def new
    @deal = Deal.new
    @stages = current_user.account.stages
    @contact = current_user.account.contacts.find(params[:deal][:contact_id])
    @deal.contact = @contact
  end

  def new_select_contact
    @deal = Deal.new
  end

  def add_contact
    @deal = Deal.find(params[:deal_id])
  end

  def commit_add_contact
    @deal = Deal.find(params[:deal_id])
    @new_contact = Contact.find(params['deal']['contact_id'])
    @deal.contacts.push(@new_contact)

    if @deal.save
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :add_contact, status: :unprocessable_entity
    end
  rescue StandardError
    render :add_contact, status: :unprocessable_entity
  end

  def remove_contact
    @deal = Deal.find(params[:deal_id])
    @contacts_deal = @deal.contacts_deals.find_by_contact_id(params['contact_id'])

    if @contacts_deal.destroy
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :show, status: :unprocessable_entity
    end
  rescue StandardError
    render :show, status: :unprocessable_entity
  end

  # GET /deals/1/edit
  def edit
    @stages = current_user.account.stages
  end

  def edit_custom_attributes
    @deal = current_user.account.deals.find(params[:deal_id])
    @custom_attribute_definitions = current_user.account.custom_attribute_definitions.deal_attribute
  end

  def update_custom_attributes
    @deal = current_user.account.deals.find(params[:deal_id])
    @deal.custom_attributes[params[:deal][:att_key]] = params[:deal][:att_value]

    if @deal.save
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :edit_custom_attributes, status: :unprocessable_entity
    end
  end

  # POST /deals or /deals.json
  def create
    @stages = current_user.account.stages
    @deal = DealBuilder.new(current_user, deal_params).perform

    if @deal.save
      redirect_to account_deal_path(current_user.account, @deal)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /deals/1 or /deals/1.json
  def update
    @stages = @deal.pipeline.stages
    if @deal.update(deal_params)
      respond_to do |format|
        format.html { redirect_to account_deal_path(current_user.account, @deal) }
        format.json { head :ok }
        format.js { head :ok }
        format.turbo_stream { head :ok }
      end
    else
      # render :edit, status: :unprocessable_entity
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @deal.errors, status: :unprocessable_entity }
        format.js { render json: @deal.errors, status: :unprocessable_entity }
        format.turbo_stream { render json: @deal.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deals/1 or /deals/1.json
  def destroy
    @deal.destroy
    respond_to do |format|
      format.html { redirect_to root_path, notice: t('flash_messages.deleted', model: Deal.model_name.human) }
      format.json { head :no_content }
    end
  end

  def events_to_do
    @pagy, @events = pagy(@deal.contact.events.where(deal_id: [nil, @deal.id]).to_do, items: 5)
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def events_done
    @pagy, @events = pagy(@deal.contact.events.where(deal_id: [nil, @deal.id]).done, items: 5)
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def deal_products
    @deal_products = @deal.deal_products
  end

  def deal_assignees
    @deal_assignees = @deal.deal_assignees
  end

  def edit_product
    @product = @deal_product.product
  end

  def update_product
    @product = @deal_product.product
    if @product.update(product_params)
      redirect_to account_deal_path(current_user.account,
                                    @deal_product.deal.id)
    else
      render :edit_product, status: :unprocessable_entity
    end
  end

  private

  def set_deal
    @deal = current_user.account.deals.find(params[:id])
  end

  def set_deal_product
    @deal_product = current_user.account.deal_products.find(params[:deal_product_id])
  end

  # Only allow a list of trusted parameters through.
  def deal_params
    params.require(:deal).permit(
      :name, :status, :stage_id, :contact_id, :position, :account_id,
      contact_attributes: %i[id full_name phone email],
      custom_attributes: {}
    )
  end
end
