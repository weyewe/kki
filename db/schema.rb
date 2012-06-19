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

ActiveRecord::Schema.define(:version => 20120524084402) do

  create_table "assignments", :force => true do |t|
    t.integer  "role_id"
    t.integer  "job_attachment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "backlog_payments", :force => true do |t|
    t.integer  "group_loan_id"
    t.integer  "weekly_task_id"
    t.integer  "member_payment_id"
    t.integer  "member_id"
    t.boolean  "is_cleared",                                    :default => false
    t.integer  "backlog_cleared_declarator_id"
    t.integer  "transaction_activity_id_for_backlog_clearance"
    t.boolean  "is_group_loan_declared_as_default",             :default => false
    t.integer  "clearance_period"
    t.integer  "backlog_type"
    t.integer  "backlog_payment_approver_id"
    t.boolean  "is_cashier_approved",                           :default => false
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
    t.decimal  "total_incoming_to_date", :precision => 13, :scale => 2, :default => 0.0
    t.decimal  "total_outgoing_to_date", :precision => 13, :scale => 2, :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "communes", :force => true do |t|
    t.string   "number"
    t.integer  "village_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "default_payments", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.decimal  "amount_sub_group_share",                 :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_group_share",                     :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_of_compulsory_savings_deduction", :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_to_be_shared_with_non_defaultee", :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "total_amount",                           :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "custom_amount",                          :precision => 10, :scale => 2
    t.decimal  "amount_paid",                            :precision => 10, :scale => 2, :default => 0.0
    t.boolean  "is_paid",                                                               :default => false
    t.decimal  "amount_assumed_by_office",               :precision => 10, :scale => 2, :default => 0.0
    t.boolean  "is_assumed_by_office",                                                  :default => false
    t.integer  "transaction_id"
    t.boolean  "is_defaultee",                                                          :default => false
    t.integer  "payment_approver_id"
    t.boolean  "is_cashier_approved",                                                   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "geo_scopes", :force => true do |t|
    t.integer  "office_id"
    t.integer  "subdistrict_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_loan_assignments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "group_loan_id"
    t.integer  "assignment_type", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_loan_memberships", :force => true do |t|
    t.integer  "group_loan_id"
    t.integer  "member_id"
    t.decimal  "deposit",                                      :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "initial_savings",                              :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "admin_fee",                                    :precision => 9, :scale => 2, :default => 0.0
    t.boolean  "has_paid_setup_fee",                                                         :default => false
    t.integer  "setup_fee_transaction_id"
    t.integer  "loan_disbursement_transaction_id"
    t.boolean  "has_received_loan_disbursement",                                             :default => false
    t.integer  "loan_disburser_id"
    t.boolean  "deduct_setup_payment_from_loan",                                             :default => false
    t.integer  "sub_group_id"
    t.boolean  "is_attending_financial_lecture"
    t.integer  "financial_lecture_attendance_marker_id"
    t.boolean  "final_financial_lecture_attendance"
    t.integer  "final_financial_lecture_attendance_marker_id"
    t.boolean  "is_attending_loan_disbursement"
    t.integer  "loan_disbursement_attendance_marker_id"
    t.boolean  "final_loan_disbursement_attendance"
    t.integer  "final_loan_disbursement_attendance_marker_id"
    t.boolean  "is_active",                                                                  :default => true
    t.integer  "deactivation_case"
    t.boolean  "is_compulsory_savings_migrated",                                             :default => false
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
    t.integer  "creator_id",                                                                                                 :null => false
    t.integer  "office_id"
    t.boolean  "is_closed",                                                                               :default => false
    t.integer  "group_loan_closer_id"
    t.boolean  "is_started",                                                                              :default => false
    t.integer  "group_loan_starter_id"
    t.boolean  "is_financial_education_attendance_done",                                                  :default => false
    t.integer  "financial_education_inspector_id"
    t.boolean  "financial_education_finalization_proposed",                                               :default => false
    t.integer  "financial_education_finalization_proposer_id"
    t.boolean  "loan_disbursement_finalization_proposed",                                                 :default => false
    t.integer  "loan_disbursement_finalization_proposer_id"
    t.boolean  "is_loan_disbursement_attendance_done",                                                    :default => false
    t.integer  "loan_disbursement_inspector_id"
    t.boolean  "is_loan_disbursement_approved",                                                           :default => false
    t.integer  "loan_disbursement_approver_id"
    t.boolean  "is_setup_fee_collection_finalized",                                                       :default => false
    t.integer  "setup_fee_collection_finalizer_id"
    t.boolean  "is_setup_fee_collection_approved",                                                        :default => false
    t.integer  "setup_fee_collection_approver_id"
    t.boolean  "is_proposed",                                                                             :default => false
    t.integer  "group_loan_proposer_id"
    t.decimal  "total_default_amount",                                     :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "total_calculated_default_absorbed_by_office",              :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "total_actual_default_absorbed_by_office",                  :precision => 11, :scale => 2, :default => 0.0
    t.boolean  "is_group_loan_default",                                                                   :default => false
    t.integer  "default_creator_id"
    t.decimal  "aggregated_principal_amount",                              :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "aggregated_interest_amount",                               :precision => 10, :scale => 2, :default => 0.0
    t.integer  "total_weeks",                                                                             :default => 0
    t.integer  "group_leader_id"
    t.integer  "commune_id"
    t.boolean  "is_default_payment_resolution_proposed",                                                  :default => false
    t.integer  "default_payment_proposer_id"
    t.boolean  "is_default_payment_resolution_approved",                                                  :default => false
    t.integer  "default_payment_resolution_approver_id"
    t.boolean  "is_custom_default_payment_resolution",                                                    :default => false
    t.decimal  "default_payment_value_before_defaultee_savings_deduction", :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "default_payment_to_be_shared_among_non_defaultee",         :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "group_loan_loss",                                          :precision => 11, :scale => 2, :default => 0.0
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

  create_table "member_attendances", :force => true do |t|
    t.integer  "weekly_task_id"
    t.integer  "attendance_status",    :default => 0
    t.integer  "attendance_marker_id"
    t.integer  "member_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "member_payments", :force => true do |t|
    t.integer  "transaction_activity_id"
    t.integer  "weekly_task_id"
    t.integer  "member_id"
    t.boolean  "has_paid",                                              :default => false
    t.boolean  "only_savings",                                          :default => false
    t.boolean  "no_payment",                                            :default => false
    t.decimal  "cash_passed",             :precision => 9, :scale => 2, :default => 0.0
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
    t.decimal  "total",                    :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "total_compulsory_savings", :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "total_extra_savings",      :precision => 11, :scale => 2, :default => 0.0
    t.integer  "member_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "saving_entries", :force => true do |t|
    t.integer  "saving_book_id"
    t.integer  "saving_entry_code"
    t.integer  "saving_action_type"
    t.integer  "transaction_entry_id"
    t.decimal  "amount",               :precision => 11, :scale => 2, :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sub_groups", :force => true do |t|
    t.integer  "group_loan_id"
    t.integer  "sub_group_leader_id"
    t.integer  "number"
    t.decimal  "sub_group_total_default_payment_amount",               :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "sub_group_default_payment_contribution_amount",        :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "actual_sub_group_default_payment_contribution_amount", :precision => 10, :scale => 2, :default => 0.0
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
    t.integer  "transaction_action_type"
    t.integer  "office_id"
    t.integer  "transaction_case"
    t.integer  "loan_type"
    t.integer  "loan_id"
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
    t.integer  "transaction_activity_id"
    t.decimal  "amount",                        :precision => 9, :scale => 2, :default => 0.0
    t.integer  "transaction_entry_action_type"
    t.integer  "cashflow_book_entry_id"
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

  create_table "weekly_tasks", :force => true do |t|
    t.integer  "group_loan_id"
    t.integer  "week_number"
    t.datetime "weekly_attendance_marking_done_time"
    t.boolean  "is_weekly_attendance_marking_done",      :default => false
    t.integer  "attendance_closer_id"
    t.datetime "weekly_payment_collection_done_time"
    t.boolean  "is_weekly_payment_collection_finalized", :default => false
    t.integer  "weekly_payment_collection_finalizer_id"
    t.boolean  "is_weekly_payment_approved_by_cashier",  :default => false
    t.integer  "weekly_payment_approver_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
