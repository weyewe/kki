# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120319042038) do

  create_table "assignments", :force => true do |t|
    t.integer  "role_id"
    t.integer  "job_attachment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cashflow_book_entries", :force => true do |t|
    t.integer  "cashflow_book_id"
    t.integer  "entry_type"
    t.decimal  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cashflow_books", :force => true do |t|
    t.integer  "office_id"
    t.decimal  "total_incoming_to_date"
    t.decimal  "total_outgoing_to_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "communes", :force => true do |t|
    t.string   "number"
    t.integer  "village_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "geo_scopes", :force => true do |t|
    t.integer  "office_id"
    t.integer  "subdistrict_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_loan_memberships", :force => true do |t|
    t.integer  "group_loan_id"
    t.integer  "member_id"
    t.decimal  "deposit",                  :precision => 9, :scale => 2, :default => 0.0
    t.boolean  "has_paid_setup_fee",                                     :default => false
    t.integer  "setup_fee_transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_loan_products", :force => true do |t|
    t.integer  "creator_id"
    t.decimal  "principal",       :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "interest",        :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "min_savings",     :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "admin_fee",       :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "initial_savings", :precision => 9, :scale => 2, :default => 0.0
    t.integer  "total_weeks"
    t.integer  "office_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_loan_subcriptions", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.integer  "group_loan_product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_loans", :force => true do |t|
    t.string   "name"
    t.integer  "creator_id",                                                                         :null => false
    t.integer  "office_id"
    t.boolean  "is_closed",                                                       :default => false
    t.integer  "group_loan_closer_id"
    t.boolean  "is_started",                                                      :default => false
    t.integer  "group_loan_starter_id"
    t.boolean  "is_loan_disbursement_done",                                       :default => false
    t.integer  "loan_disburser_id"
    t.boolean  "is_setup_fee_collection_approved",                                :default => false
    t.integer  "setup_fee_collection_approver_id"
    t.boolean  "is_proposed",                                                     :default => false
    t.integer  "group_loan_proposer_id"
    t.decimal  "total_default",                    :precision => 11, :scale => 2, :default => 0.0
    t.boolean  "any_default",                                                     :default => false
    t.integer  "default_creator_id"
    t.decimal  "aggregated_principal_amount",      :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "aggregated_interest_amount",       :precision => 10, :scale => 2, :default => 0.0
    t.integer  "commune_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "islands", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "job_attachments", :force => true do |t|
    t.integer  "office_id"
    t.integer  "user_id"
    t.boolean  "is_active",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "member_payments", :force => true do |t|
    t.integer  "member_id"
    t.integer  "amount"
    t.integer  "payment_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "members", :force => true do |t|
    t.string   "name"
    t.string   "id_card_no"
    t.integer  "village_id"
    t.integer  "commune_id"
    t.integer  "neighborhood_no"
    t.text     "address"
    t.integer  "creator_id"
    t.integer  "office_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "offices", :force => true do |t|
    t.string   "name"
    t.integer  "regency_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "provinces", :force => true do |t|
    t.string   "name"
    t.integer  "island_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "regencies", :force => true do |t|
    t.string   "name"
    t.integer  "province_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "saving_books", :force => true do |t|
    t.decimal  "total",      :precision => 11, :scale => 2, :default => 0.0
    t.integer  "member_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "saving_entries", :force => true do |t|
    t.integer  "saving_book_id"
    t.integer  "saving_entry_code"
    t.decimal  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subdistricts", :force => true do |t|
    t.string   "name"
    t.integer  "regency_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timeline_activities", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transaction_activities", :force => true do |t|
    t.integer  "creator_id"
    t.decimal  "total_transaction_amount", :precision => 9, :scale => 2, :default => 0.0
    t.boolean  "from_member",                                            :default => true
    t.integer  "member_id"
    t.integer  "office_id"
    t.integer  "transaction_case"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transaction_books", :force => true do |t|
    t.integer  "member_id"
    t.integer  "creator_id"
    t.decimal  "total",      :precision => 12, :scale => 2, :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transaction_entries", :force => true do |t|
    t.integer  "transaction_book_id"
    t.integer  "transaction_entry_code"
    t.decimal  "amount"
    t.integer  "cashflow_book_entry"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "username",               :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "villages", :force => true do |t|
    t.string   "name"
    t.integer  "subdistrict_id"
    t.string   "postal_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "weekly_attendances", :force => true do |t|
    t.integer  "week"
    t.date     "meeting_date"
    t.time     "meeting_time"
    t.integer  "group_id"
    t.integer  "membership_id"
    t.boolean  "is_attending"
    t.integer  "field_worker_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "weekly_payments", :force => true do |t|
    t.integer  "week"
    t.integer  "group_id"
    t.integer  "membership_id"
    t.integer  "amount_paid"
    t.integer  "debt_collector_id"
    t.boolean  "is_cashier_approved"
    t.integer  "cashier_id"
    t.integer  "payment_status",                   :default => 0
    t.integer  "less_than_minimum_payment_amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "weekly_tasks", :force => true do |t|
    t.integer  "group_loan_id"
    t.integer  "total_attendance"
    t.decimal  "total_payment_amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
