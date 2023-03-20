class Accounts::Apps::WppConnects::Webhooks::Status

  def self.call(wpp_connect, webhook)
    if (webhook['status'] == 'inChat')
      wpp_connect.update(active: true)
      Accounts::Apps::WppConnects::Sync::FullSyncWorker.perform_async(wpp_connect.id)
    end

    return { ok: wpp_connect }
  end
end