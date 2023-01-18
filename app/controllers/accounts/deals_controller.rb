class Accounts::DealsController < InternalController
  before_action :set_deal, only: %i[ show edit update destroy ]

  # GET /deals or /deals.json
  def index
    @deals = Deal.all
  end

  # GET /deals/1 or /deals/1.json
  def show
    @note = Note.new
    @activity = Activity.new
    @event = Event.new

    @events = @deal.contact.events
    @pagy, @events = pagy(@events)
  end

  # GET /deals/new
  def new
    @deal = Deal.new
    if params[:deal][:contact_id].present? && params[:deal][:contact_id] != '0'
      @deal.contact = Contact.find(params[:deal][:contact_id])
      @deal.contact_id = params[:deal][:contact_id]
    else
      @deal.build_contact
    end
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

    rescue
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

    rescue
      render :show, status: :unprocessable_entity
  end

  # GET /deals/1/edit
  def edit
  end

  # POST /deals or /deals.json
  def create
    @deal = Deal.new(deal_params)

    respond_to do |format|
      if @deal.save
        format.html { redirect_to account_deal_path(current_user.account, @deal), notice: "Deal was successfully created." }
        format.json { render :show, status: :created, location: @deal }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @deal.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_whatsapp
    @deal = Deal.find(params['deal_id'])
    result = FlowItems::ActivitiesKinds::WpConnect::Messages::Create.call(whatsapp_params.merge({'contact_id': @deal.contact.id}))

    respond_to do |format|
      if result.key?(:ok)
        format.html { redirect_to @deal }
        format.json { render :show, status: :created, location: @deal }
      else
        format.html { redirect_to @deal }
        format.json { render json: @deal.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deals/1 or /deals/1.json
  def update
    respond_to do |format|
      if @deal.update(deal_params)
        format.html { redirect_to account_deal_path(current_user.account, @deal), notice: "Deal was successfully updated." }
        format.json { render :show, status: :ok, location: @deal }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @deal.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deals/1 or /deals/1.json
  def destroy
    @deal.destroy
    respond_to do |format|
      format.html { redirect_to deals_url, notice: "Deal was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deal
      @deal = Deal.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def deal_params
      params.require(:deal).permit(
        :name, :status, :stage_id, :contact_id,
        contact_attributes: [ :id, :full_name, :phone, :email ],
        custom_attributes: {}
      )
    end

    def whatsapp_params
      params.require(:flow_item).permit(
        :content, :kind_id
      )
    end
end
