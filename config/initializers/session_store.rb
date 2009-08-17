# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_houdini_session',
  :secret      => 'd41dcdb7aa9a76438c1f84969f83f667d4a93bff76c8b7dedbd10280e757ebbc96dc9f0341a11ffbd00ef328abd93469c2f877a0ed8e39a4e14998984e087526'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
