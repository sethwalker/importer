class SummaryMailer < ActionMailer::Base
  def summary(url, recipient, message)
    from       ENV['from_address']
    recipients recipient
    subject    "[#{url}] Batch import completed"
    body       "Importer successfully completed your import. \n\n#{message}"
  end
end
