require 'rails_helper'

RSpec.describe Accounts::DealAssigneesController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:contact) { create(:contact, account:) }
  let!(:pipeline) { create(:pipeline, account:) }
  let!(:stage) { create(:stage, pipeline:, account:) }
  let!(:deal) { create(:deal, stage:, contact:, account:) }

  describe 'DELETE /accounts/{account.id}/deal_assignees/{deal_assignee.id}' do
    let!(:deal_assignee) { create(:deal_assignee, deal:, user:) }
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/deal_assignees/#{deal_assignee.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'should delete deal_assignee' do
        it do
          expect do
            delete "/accounts/#{account.id}/deal_assignees/#{deal_assignee.id}"
          end.to change(DealAssignee, :count).by(-1)
          expect(response).to have_http_status(:redirect)
        end
      end
    end
  end

  describe 'GET /accounts/{account.id}/deal_assignees/new?deal_id={deal.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deal_assignees/new?deal_id=#{deal.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'should access deal_assignee new page' do
        it do
          get "/accounts/#{account.id}/deal_assignees/new?deal_id=#{deal.id}"
          expect(response).to have_http_status(200)
          expect(response.body).to include('select_user_search')
        end
      end
    end
  end

  describe 'POST /accounts/{account.id}/deal_assignees' do
    let(:valid_params) { { deal_assignee: { deal_id: deal.id, user_id: user.id } } }
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/deal_assignees", params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'should create deal_assignee' do
        it do
          expect do
            post "/accounts/#{account.id}/deal_assignees", params: valid_params
          end.to change(DealAssignee, :count).by(1)
          expect(response).to have_http_status(302)
        end
      end
      context 'when params is not valid' do
        context 'when params not contain deal_id' do
          it 'should raise an error' do
            invalid_params = { deal_assignee: { user_id: user.id } }
            expect do
              post "/accounts/#{account.id}/deal_assignees", params: invalid_params
            end.to change(DealAssignee, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('Deal must exist')
          end
        end
        context 'when params not contain user_id' do
          it 'should raise an error' do
            invalid_params = { deal_assignee: { deal_id: deal.id } }
            expect do
              post "/accounts/#{account.id}/deal_assignees", params: invalid_params
            end.to change(DealAssignee, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('User must exist')
          end
        end
        context 'when deal_assignee already associated with the user and deal' do
          let!(:deal_assignee) { create(:deal_assignee, deal:, user:) }
          it 'should raise an error' do
            invalid_params = { deal_assignee: { deal_id: deal.id, user_id: user.id } }
            expect do
              post "/accounts/#{account.id}/deal_assignees", params: invalid_params
            end.to change(DealAssignee, :count).by(0)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include('User is already associated with this deal')
          end
        end
      end
    end
  end
  describe 'GET /accounts/{account.id}/deal_assignees/select_user_search?query=query' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/deal_assignees/select_user_search?query=query"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end
      context 'select user search component' do
        it do
          get "/accounts/#{account.id}/deal_assignees/select_user_search"
          expect(response).to have_http_status(200)
        end
        context 'when there is query parameter' do
          context 'when there is full_name parameter' do
            it 'should return user' do
              get "/accounts/#{account.id}/deal_assignees/select_user_search?query=#{user.full_name}"
              expect(response).to have_http_status(200)
              expect(response.body).to include(user.full_name)
            end
          end
          context 'when there is phone parameter' do
            it 'should return user' do
              query = ERB::Util.url_encode(user.phone)
              get "/accounts/#{account.id}/deal_assignees/select_user_search?query=#{query}"
              expect(response).to have_http_status(200)
              expect(response.body).to include(user.full_name)
            end
          end
          context 'when there is email parameter' do
            it 'should return user' do
              get "/accounts/#{account.id}/deal_assignees/select_user_search?query=#{user.email}"
              expect(response).to have_http_status(200)
              expect(response.body).to include(user.email)
            end
          end

          context 'when query paramenter is not founded' do
            it 'should return 0 users' do
              get "/accounts/#{account.id}/deal_assignees/select_user_search?query=teste"
              expect(response).to have_http_status(200)
              expect(response.body).not_to include('teste')
              expect(response.body).not_to include(user.full_name)
            end
          end
        end
      end
    end
  end
end
