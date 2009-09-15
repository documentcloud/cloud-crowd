# Complete schema for CloudCrowd.
ActiveRecord::Schema.define(:version => 1) do

  create_table "jobs", :force => true do |t|
    t.integer  "status",                      :null => false
    t.text     "inputs",                      :null => false
    t.string   "action",                      :null => false
    t.text     "options",                     :null => false
    t.text     "outputs"
    t.float    "time"
    t.string   "callback_url"
    t.string   "email"
    t.integer  "lock_version", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  
  create_table "node_records", :force => true do |t|
    t.string   "host",        :null => false
    t.string   "ip_address",  :null => false
    t.integer  "port",        :null => false
    t.integer  "status",      :null => false
  end

  create_table "work_units", :force => true do |t|
    t.integer  "status",                          :null => false
    t.integer  "job_id",                          :null => false
    t.text     "input",                           :null => false
    t.string   "action",                          :null => false
    t.integer  "attempts",     :default => 0,     :null => false
    t.integer  "lock_version", :default => 0,     :null => false
    t.integer  "node_record_id"
    t.integer  "worker_pid"
    t.float    "time"
    t.text     "output"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jobs", ["status"], :name => "index_jobs_on_status"
  add_index "work_units", ["job_id"], :name => "index_work_units_on_job_id"
  add_index "work_units", ["status", "worker_record_id", "action"], :name => "index_work_units_on_status_and_worker_record_id_and_action"

end
