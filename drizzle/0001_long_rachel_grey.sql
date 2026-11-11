CREATE TABLE "audit_logs" (
	"audit_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "audit_logs_audit_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"user_id" bigint,
	"action" varchar(100) NOT NULL,
	"table_name" varchar(100),
	"record_id" bigint,
	"old_values" jsonb,
	"new_values" jsonb,
	"ip_address" "inet",
	"created_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "commuters" (
	"commuter_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "commuters_commuter_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"user_id" bigint,
	"full_name" varchar(150),
	"mobile_number" varchar(20),
	"created_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "payment_callbacks" (
	"callback_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "payment_callbacks_callback_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"transaction_id" bigint,
	"provider_reference" varchar(150),
	"callback_payload" jsonb,
	"verification_status" varchar(20) DEFAULT 'PENDING',
	"received_at" timestamp with time zone DEFAULT now(),
	"processed_at" timestamp with time zone,
	CONSTRAINT "payment_callbacks_verification_status_check" CHECK ("payment_callbacks"."verification_status" IN ('PENDING', 'VERIFIED', 'REJECTED'))
);
--> statement-breakpoint
CREATE TABLE "qr_codes" (
	"qr_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "qr_codes_qr_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"taxi_id" bigint NOT NULL,
	"assignment_id" bigint NOT NULL,
	"qr_token_hash" text NOT NULL,
	"generated_at" timestamp with time zone DEFAULT now(),
	"expires_at" timestamp with time zone,
	"status" varchar(20) DEFAULT 'ACTIVE',
	CONSTRAINT "qr_codes_qr_token_hash_unique" UNIQUE("qr_token_hash"),
	CONSTRAINT "qr_codes_status_check" CHECK ("qr_codes"."status" IN ('ACTIVE', 'REVOKED', 'EXPIRED'))
);
--> statement-breakpoint
CREATE TABLE "receipts" (
	"receipt_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "receipts_receipt_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"transaction_id" bigint NOT NULL,
	"receipt_number" varchar(100) NOT NULL,
	"issued_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "receipts_transaction_id_unique" UNIQUE("transaction_id"),
	CONSTRAINT "receipts_receipt_number_unique" UNIQUE("receipt_number")
);
--> statement-breakpoint
CREATE TABLE "refunds" (
	"refund_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "refunds_refund_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"transaction_id" bigint NOT NULL,
	"refund_reference" varchar(150) NOT NULL,
	"refund_amount" numeric(12, 2) NOT NULL,
	"reason" text,
	"status" varchar(20) DEFAULT 'PENDING',
	"requested_by" bigint,
	"approved_by" bigint,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "refunds_refund_reference_unique" UNIQUE("refund_reference"),
	CONSTRAINT "refunds_status_check" CHECK ("refunds"."status" IN ('PENDING', 'APPROVED', 'REJECTED', 'SUCCESS', 'FAILED')),
	CONSTRAINT "refunds_refund_amount_check" CHECK ("refunds"."refund_amount" > 0)
);
--> statement-breakpoint
CREATE TABLE "tariffs" (
	"tariff_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "tariffs_tariff_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"tariff_name" varchar(100) NOT NULL,
	"tariff_per_km" numeric(10, 2) NOT NULL,
	"minimum_fare" numeric(10, 2) DEFAULT '0',
	"effective_from" timestamp with time zone NOT NULL,
	"effective_to" timestamp with time zone,
	"status" varchar(20) DEFAULT 'PENDING',
	"created_by" bigint,
	"approved_by" bigint,
	"approved_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "tariffs_status_check" CHECK ("tariffs"."status" IN ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED')),
	CONSTRAINT "tariffs_tariff_per_km_check" CHECK ("tariffs"."tariff_per_km" > 0),
	CONSTRAINT "tariffs_minimum_fare_check" CHECK ("tariffs"."minimum_fare" >= 0),
	CONSTRAINT "tariffs_effective_period_check" CHECK ("tariffs"."effective_to" IS NULL OR "tariffs"."effective_to" > "tariffs"."effective_from")
);
--> statement-breakpoint
CREATE TABLE "transactions" (
	"transaction_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "transactions_transaction_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"transaction_reference" uuid DEFAULT gen_random_uuid() NOT NULL,
	"commuter_id" bigint,
	"taxi_id" bigint NOT NULL,
	"assignment_id" bigint NOT NULL,
	"qr_id" bigint,
	"route_id" bigint NOT NULL,
	"boarding_stage_id" bigint NOT NULL,
	"destination_stage_id" bigint NOT NULL,
	"distance_km" numeric(10, 2) NOT NULL,
	"tariff_id" bigint NOT NULL,
	"applied_tariff_per_km" numeric(10, 2) NOT NULL,
	"fare_amount" numeric(12, 2) NOT NULL,
	"payment_method" varchar(30) DEFAULT 'TELEBIRR',
	"telebirr_reference" varchar(150),
	"payment_status" varchar(20) DEFAULT 'PENDING',
	"payment_initiated_at" timestamp with time zone DEFAULT now(),
	"payment_completed_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "transactions_transaction_reference_unique" UNIQUE("transaction_reference"),
	CONSTRAINT "transactions_telebirr_reference_unique" UNIQUE("telebirr_reference"),
	CONSTRAINT "transactions_payment_status_check" CHECK ("transactions"."payment_status" IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED', 'REFUNDED', 'PARTIALLY_REFUNDED')),
	CONSTRAINT "transactions_distance_check" CHECK ("transactions"."distance_km" > 0),
	CONSTRAINT "transactions_fare_amount_check" CHECK ("transactions"."fare_amount" > 0),
	CONSTRAINT "transactions_applied_tariff_check" CHECK ("transactions"."applied_tariff_per_km" > 0),
	CONSTRAINT "transactions_stage_difference_check" CHECK ("transactions"."boarding_stage_id" <> "transactions"."destination_stage_id")
);
--> statement-breakpoint
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_users_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "commuters" ADD CONSTRAINT "commuters_user_id_users_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "payment_callbacks" ADD CONSTRAINT "payment_callbacks_transaction_id_transactions_transaction_id_fk" FOREIGN KEY ("transaction_id") REFERENCES "public"."transactions"("transaction_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "qr_codes" ADD CONSTRAINT "qr_codes_taxi_id_taxis_taxi_id_fk" FOREIGN KEY ("taxi_id") REFERENCES "public"."taxis"("taxi_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "qr_codes" ADD CONSTRAINT "qr_codes_assignment_id_taxi_route_assignments_assignment_id_fk" FOREIGN KEY ("assignment_id") REFERENCES "public"."taxi_route_assignments"("assignment_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "receipts" ADD CONSTRAINT "receipts_transaction_id_transactions_transaction_id_fk" FOREIGN KEY ("transaction_id") REFERENCES "public"."transactions"("transaction_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_transaction_id_transactions_transaction_id_fk" FOREIGN KEY ("transaction_id") REFERENCES "public"."transactions"("transaction_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_requested_by_users_user_id_fk" FOREIGN KEY ("requested_by") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_approved_by_users_user_id_fk" FOREIGN KEY ("approved_by") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tariffs" ADD CONSTRAINT "tariffs_created_by_users_user_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "tariffs" ADD CONSTRAINT "tariffs_approved_by_users_user_id_fk" FOREIGN KEY ("approved_by") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_commuter_id_commuters_commuter_id_fk" FOREIGN KEY ("commuter_id") REFERENCES "public"."commuters"("commuter_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_taxi_id_taxis_taxi_id_fk" FOREIGN KEY ("taxi_id") REFERENCES "public"."taxis"("taxi_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_assignment_id_taxi_route_assignments_assignment_id_fk" FOREIGN KEY ("assignment_id") REFERENCES "public"."taxi_route_assignments"("assignment_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_qr_id_qr_codes_qr_id_fk" FOREIGN KEY ("qr_id") REFERENCES "public"."qr_codes"("qr_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_route_id_routes_route_id_fk" FOREIGN KEY ("route_id") REFERENCES "public"."routes"("route_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_tariff_id_tariffs_tariff_id_fk" FOREIGN KEY ("tariff_id") REFERENCES "public"."tariffs"("tariff_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_boarding_stage_fk" FOREIGN KEY ("route_id","boarding_stage_id") REFERENCES "public"."route_stages"("route_id","stage_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_destination_stage_fk" FOREIGN KEY ("route_id","destination_stage_id") REFERENCES "public"."route_stages"("route_id","stage_id") ON DELETE no action ON UPDATE no action;