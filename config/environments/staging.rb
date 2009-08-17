# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = false

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"
#config.action_controller.asset_host = "http://assets%d.opencongress.org"

# Disable delivery errors if you bad email addresses should just be ignored
# config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :sendmail
config.action_mailer.sendmail_settings = {
  :location       => '/usr/sbin/sendmail',
  :arguments      => '-XV -f bounces-main -i -t'
}


config.cache_store = :mem_cache_store, 'localhost:11211', { :namespace => 'opencongress_staging' }

BASE_URL = 'http://dev.opencongress.org/'

GOVTRACK_DATA_PATH = '/data/govtrack/111'
GOVTRACK_BILLTEXT_PATH = "/data/govtrack/bills.text/111"
GOVTRACK_BILLTEXT_DIFF_PATH = "/data/govtrack/bills.text.cmp"
OC_BILLTEXT_PATH = "/data/opencongress/bills.text"
COMMITTEE_REPORTS_PATH = '/data/committee_reports/'
CRP_DATA_PATH = '/data/crp'
WIKI_URL = 'http://wiki-dev.opencongress.org/wiki'

# the following API key is for OpenCongress production use only!
TECHNORATI_API_KEY = '0d8ad0bcf220c84bca12ecfdcb744b50'

WIKI_BASE = "http://wiki-dev.opencongress.org"
MINI_MAILER_FROM = "alerts@dev.opencongress.org"

