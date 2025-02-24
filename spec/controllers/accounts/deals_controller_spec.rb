require 'rails_helper'

RSpec.describe Accounts::DealsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:pipeline) { create(:pipeline, account:) }
  let!(:stage) { create(:stage, account:, pipeline:) }
  let!(:stage_2) { create(:stage, account:, pipeline:, name: 'Stage 2') }
  let!(:contact) { create(:contact, account:) }
  let(:event) { create(:event, account:, deal:, kind: 'activity') }
  let(:last_event) { Event.last }
  let(:last_deal) { Deal.last }

  describe 'POST /accounts/{account.id}/deals' do
    let(:valid_params) { { deal: { name: 'Deal 1', contact_id: contact.id, stage_id: stage.id } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/accounts/#{account.id}/deals", params: valid_params }.not_to change(Deal, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'create deal and deal_opened event' do
        it do
          expect do
            post "/accounts/#{account.id}/deals",
                 params: valid_params
          end.to change(Deal, :count).by(1)
                                     .and change(Event, :count).by(1)
          expect(response).to redirect_to(account_deal_path(account, last_deal))
          expect(last_event.kind).to eq('deal_opened')
          expect(last_deal.creator).to eq(user)
        end
      end
    end
  end

  describe 'PUT /accounts/{account.id}/deals/:id' do
    let!(:deal) { create(:deal, account:, stage:) }
    let(:valid_params) { { deal: { name: 'Deal Updated' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/accounts/#{account.id}/deals/#{deal.id}", params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'should update deal ' do
        it do
          put "/accounts/#{account.id}/deals/#{deal.id}",
              params: valid_params

          # expect(response).to have_http_status(:success)
          expect(deal.reload.name).to eq('Deal Updated')
        end
      end
      context 'update deal position and create deal_stage_change event' do
        around(:each) do |example|
          Sidekiq::Testing.inline! do
            example.run
          end
        end
        let!(:deal_stage_1_position_1) { create(:deal, account:, stage:, position: 1) }
        let!(:deal_stage_1_position_2) { create(:deal, account:, stage:, position: 2) }
        let!(:deal_stage_1_position_3) { create(:deal, account:, stage:, position: 3) }
        let!(:deal_stage_2_position_1) { create(:deal, account:, stage: stage_2, position: 1) }
        let!(:deal_stage_2_position_2) { create(:deal, account:, stage: stage_2, position: 2) }
        let!(:deal_stage_2_position_3) { create(:deal, account:, stage: stage_2, position: 3) }
        skip 'between different stages' do
          it 'stage 1 position 3 to stage 2 position 1' do
            params =  { deal: { stage_id: stage_2.id, position: 1 } }

            put("/accounts/#{account.id}/deals/#{deal_stage_1_position_3.id}",
                params:)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_3.reload.position).to eq(1)
            expect(deal_stage_1_position_3.reload.stage).to eq(stage_2)
            expect(deal_stage_2_position_1.reload.position).to eq(2)
          end
          it 'stage 1 position 1 to stage 2 position 1' do
            params =  { deal: { stage_id: stage_2.id, position: 1 } }
            expect do
              put("/accounts/#{account.id}/deals/#{deal_stage_1_position_1.id}",
                  params:)
            end.to change(Event, :count).by(1)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_1.reload.position).to eq(1)
            expect(deal_stage_1_position_1.reload.stage).to eq(stage_2)
            expect(deal_stage_2_position_1.reload.position).to eq(2)
            expect(last_event.kind).to eq('deal_stage_change')
          end
        end
        context 'in the same stage' do
          it 'position 3 to position 1' do
            params = { deal: { stage_id: stage.id, position: 1 } }
            put("/accounts/#{account.id}/deals/#{deal_stage_1_position_3.id}",
                params:)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_3.reload.position).to eq(1)
            expect(deal_stage_1_position_3.reload.stage).to eq(stage)
          end
          it 'position 1 to position 3' do
            params = { deal: { stage_id: stage.id, position: 3 } }
            put("/accounts/#{account.id}/deals/#{deal_stage_1_position_1.id}",
                params:)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_1.reload.position).to eq(3)
            expect(deal_stage_1_position_1.reload.stage).to eq(stage)
          end
          it 'position 2 to position 1' do
            params = { deal: { stage_id: stage.id, position: 1 } }
            put("/accounts/#{account.id}/deals/#{deal_stage_1_position_2.id}",
                params:)
            # expect(response).to have_http_status(:success)
            expect(deal_stage_1_position_2.reload.position).to eq(1)
            expect(deal_stage_1_position_2.reload.stage).to eq(stage)
          end
        end
      end

      context 'update status deal' do
        it 'update to won and create deal_won event' do
          params = { deal: { status: 'won' } }
          expect do
            put("/accounts/#{account.id}/deals/#{deal.id}",
                params:)
          end.to change(Event, :count).by(1)
          expect(last_event.kind).to eq('deal_won')
        end
        it 'update to lost and create deal_lost event' do
          params = { deal: { status: 'lost' } }
          expect do
            put("/accounts/#{account.id}/deals/#{deal.id}",
                params:)
          end.to change(Event, :count).by(1)
          expect(last_event.kind).to eq('deal_lost')
        end
        context 'when deal is won ' do
          let!(:won_deal) { create(:deal, account:, stage:, status: 'won') }
          it 'update to open and create reopen_lost event' do
            params = { deal: { status: 'open' } }
            expect do
              put("/accounts/#{account.id}/deals/#{won_deal.id}",
                  params:)
            end.to change(Event, :count).by(1)
            expect(last_event.kind).to eq('deal_reopened')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id' do
    let(:deal) { create(:deal, account:, stage:, creator: user) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}"

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'shows the deal' do
        get "/accounts/#{account.id}/deals/#{deal.id}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include(deal.name)
        expect(response.body).to include(deal.creator.full_name)
      end
      context 'when there is no creator associated with the deal' do
        let(:deal_with_no_creator) { create(:deal, account:, stage:) }

        it 'should not display Created by field' do
          get "/accounts/#{account.id}/deals/#{deal_with_no_creator.id}"

          expect(response).to have_http_status(:success)
          expect(response.body).to include(deal_with_no_creator.name)
          expect(response.body).not_to include('Created by')
        end
      end
    end
  end
  describe 'DELETE /accounts/{account.id}/deals/:id' do
    let!(:deal) { create(:deal, account:, stage:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}"

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'delete deal' do
        it do
          expect do
            delete "/accounts/#{account.id}/deals/#{deal.id}"
            expect(response).to redirect_to(root_path)
          end.to change(Deal, :count).by(-1)
        end
        it 'with events' do
          event
          expect do
            delete "/accounts/#{account.id}/deals/#{deal.id}"
            expect(response).to redirect_to(root_path)
          end.to change(Deal, :count).by(-1) and change(Contact, :count).by(-1)
          expect(account.events.count).to eq(0)
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/edit' do
    let!(:deal) { create(:deal, account:, stage:, contact:, creator: user) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      it 'should show edit deal page' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit"
        expect(response).to have_http_status(200)
        expect(response).not_to include('Created by')
      end
    end
  end

  describe 'test events to do and done pages' do
    let!(:deal) { create(:deal, account:, stage:, contact:) }
    let!(:event_to_do) do
      create(:event, account:, deal:, kind: 'activity', title: 'event to do', contact:)
    end
    let!(:event_done) do
      create(:event, account:, deal:, kind: 'activity', title: 'event done',
                     done_at: Time.current - 3.minutes, contact:)
    end

    describe 'GET /accounts/{account.id}/deals/:id/events_to_do' do
      context 'when it is an unauthenticated user' do
        it 'returns unauthorized' do
          get "/accounts/#{account.id}/deals/#{deal.id}/events_to_do"
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when it is an authenticated user' do
        before do
          sign_in(user)
        end

        it 'should return only to_do events' do
          get "/accounts/#{account.id}/deals/#{deal.id}/events_to_do"
          expect(response.body).to include('event to do')
          expect(response.body).not_to include('event done')
          expect(response.body).not_to include('id="pagination"')
        end
        context 'check if pagination is enabled' do
          it 'should return turboframe with id pagination' do
            5.times do
              create(:event, account:, deal:, kind: 'activity', title: 'event to do', contact:)
            end
            get "/accounts/#{account.id}/deals/#{deal.id}/events_to_do"
            expect(response.body).to include('id="pagination_events_to_do"')
          end
        end
      end
    end
    describe 'GET /accounts/{account.id}/deals/:id/events_done' do
      context 'when it is an unauthenticated user' do
        it 'returns unauthorized' do
          get "/accounts/#{account.id}/deals/#{deal.id}/events_done"
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'when it is an authenticated user' do
        before do
          sign_in(user)
        end

        it 'should return only done events' do
          get "/accounts/#{account.id}/deals/#{deal.id}/events_done"
          expect(response.body).to include('event done')
          expect(response.body).not_to include('event to do')
          expect(response.body).not_to include('id="pagination"')
        end
        context 'check if pagination is enabled' do
          it 'should return turboframe with id pagination' do
            5.times do
              create(:event, account:, deal:, kind: 'activity', title: 'event done',
                             done_at: Time.current - 3.minutes, contact:)
            end
            get "/accounts/#{account.id}/deals/#{deal.id}/events_done"
            expect(response.body).to include('id="pagination_events_done"')
          end
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/deal_products' do
    let!(:deal) { create(:deal, account:, stage:, contact:) }
    let(:product) { create(:product, account:) }
    let!(:deal_product) { create(:deal_product, account:, deal:, product:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/deal_products"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'should return only deal_products' do
        get "/accounts/#{account.id}/deals/#{deal.id}/deal_products"
        expect(response.body).to include(product.name)
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/deal_assignees' do
    let!(:deal) { create(:deal, account:, stage:, contact:) }
    let!(:deal_assignee) { create(:deal_assignee, deal:, user:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/deal_assignees"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      it 'should return only deal_assignees' do
        get "/accounts/#{account.id}/deals/#{deal.id}/deal_assignees"
        expect(response.body).to include(user.full_name)
      end
    end
  end

  describe 'GET /accounts/{account.id}/deals/:id/edit_product?deal_product_id={deal_product.id}' do
    let!(:deal) { create(:deal, account:, stage:, contact:) }
    let(:product) { create(:product, account:) }
    let!(:deal_product) { create(:deal_product, account:, deal:, product:) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit_product?deal_product_id=#{deal_product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      it 'edit product on deal page' do
        get "/accounts/#{account.id}/deals/#{deal.id}/edit_product?deal_product_id=#{deal_product.id}"
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/deals/:id/update_product?deal_product_id={deal_product.id}' do
    let!(:deal) { create(:deal, account:, stage:, contact:) }
    let(:product) { create(:product, account:) }
    let!(:deal_product) { create(:deal_product, account:, deal:, product:) }
    let(:valid_params) do
      { product: { name: 'Product Updated Name', amount_in_cents: '63.580,36' } }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/deals/#{deal.id}/update_product?deal_product_id=#{deal_product.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'update product' do
        it do
          patch "/accounts/#{account.id}/deals/#{deal.id}/update_product?deal_product_id=#{deal_product.id}",
                params: valid_params
          expect(response).to have_http_status(302)
          expect(product.reload.name).to eq('Product Updated Name')
          expect(product.amount_in_cents).to eq(6_358_036)
        end
        context 'when quantity_available is invalid' do
          it 'when quantity_available is negative' do
            invalid_params = { product: { quantity_available: '-30' } }
            patch "/accounts/#{account.id}/deals/#{deal.id}/update_product?deal_product_id=#{deal_product.id}",
                  params: invalid_params
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end

        context 'when amount_in_cents is invalid' do
          it 'when amount_in_cents is negative' do
            invalid_params = { product: { amount_in_cents: '-150000' } }
            patch "/accounts/#{account.id}/deals/#{deal.id}/update_product?deal_product_id=#{deal_product.id}",
                  params: invalid_params
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Can not be negative')
          end
        end
      end
    end
  end
end
