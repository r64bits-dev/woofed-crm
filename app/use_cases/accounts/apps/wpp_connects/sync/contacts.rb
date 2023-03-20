class Accounts::Apps::WppConnects::Sync::Contacts

  def self.call(wpp_connect_id)
    wpp_connect = Apps::WppConnect.find(wpp_connect_id)

    return {ok: import_groups(wpp_connect)}
  end

  def self.import_groups(wpp_connect)
    response = Faraday.get(
      "#{wpp_connect.endpoint_url}/api/#{wpp_connect.session}/all-groups",
      {},
      {'Authorization': "Bearer #{wpp_connect.token}", 'Content-Type': 'application/json'}
    )

    body = JSON.parse(response.body)
    body['response'].each do | group |
      Contact.create(
        full_name: "Grupo - #{group['name']}",
        phone: group['id']['user'],
        app: wpp_connect,
        account: wpp_connect.account,
        additional_attributes: {'wpp_connect_id': group['id']['user'] }
      )
    end
  end
end