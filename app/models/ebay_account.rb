# == Schema Information
# Schema version: 20081117161638
#
# Table name: ebay_accounts
#
#  id                :integer(11)     not null, primary key
#  name              :string(255)
#  ebay_id           :string(255)
#  ebay_site_id      :integer(11)
#  paypal_account    :string(255)
#  ebay_token        :text
#  ebay_token_expiry :string(255)
#  shop              :string(255)
#  country           :string(255)
#  city              :string(255)
#  province          :string(255)
#  time_zone         :string(255)
#  currency          :string(255)     default("USD")
#  created_at        :datetime
#  updated_at        :datetime
#

class EbayAccount < ActiveRecord::Base
  validates_presence_of :shop
  has_many :ebay_imports
  
  def ebay_site
    @site ||= Site.find_by_ebay_id(ebay_site_id)
  end
  
  def ebay
    @ebay ||= Ebay::Api.new(:auth_token => ebay_token)
  end
end
