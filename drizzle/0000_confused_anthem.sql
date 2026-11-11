CREATE TABLE "associations" (
	"association_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "associations_association_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"association_name" varchar(150) NOT NULL,
	"registration_number" varchar(50),
	"contact_person" varchar(150),
	"mobile_number" varchar(20),
	"address" text,
	"status" varchar(20) DEFAULT 'ACTIVE',
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "associations_registration_number_unique" UNIQUE("registration_number"),
	CONSTRAINT "associations_status_check" CHECK ("associations"."status" IN ('ACTIVE', 'INACTIVE'))
);
--> statement-breakpoint
CREATE TABLE "drivers" (
	"driver_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "drivers_driver_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"user_id" bigint,
	"full_name" varchar(150) NOT NULL,
	"mobile_number" varchar(20) NOT NULL,
	"license_number" varchar(50),
	"license_expiry" date,
	"status" varchar(20) DEFAULT 'ACTIVE',
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "drivers_mobile_number_unique" UNIQUE("mobile_number"),
	CONSTRAINT "drivers_license_number_unique" UNIQUE("license_number"),
	CONSTRAINT "drivers_status_check" CHECK ("drivers"."status" IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))
);
--> statement-breakpoint
CREATE TABLE "roles" (
	"role_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "roles_role_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"role_name" varchar(50) NOT NULL,
	"description" text,
	CONSTRAINT "roles_role_name_unique" UNIQUE("role_name")
);
--> statement-breakpoint
CREATE TABLE "route_stages" (
	"stage_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "route_stages_stage_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"route_id" bigint NOT NULL,
	"stage_name" varchar(150) NOT NULL,
	"stage_order" integer NOT NULL,
	"distance_from_start_km" numeric(10, 2) NOT NULL,
	CONSTRAINT "route_stages_route_order_unique" UNIQUE("route_id","stage_order"),
	CONSTRAINT "route_stages_route_stage_unique" UNIQUE("route_id","stage_id")
);
--> statement-breakpoint
CREATE TABLE "routes" (
	"route_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "routes_route_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"route_name" varchar(150) NOT NULL,
	"start_point" varchar(150) NOT NULL,
	"end_point" varchar(150) NOT NULL,
	"total_distance_km" numeric(10, 2) NOT NULL,
	"status" varchar(20) DEFAULT 'ACTIVE',
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "routes_status_check" CHECK ("routes"."status" IN ('ACTIVE', 'INACTIVE'))
);
--> statement-breakpoint
CREATE TABLE "taxi_route_assignments" (
	"assignment_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "taxi_route_assignments_assignment_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"taxi_id" bigint NOT NULL,
	"route_id" bigint NOT NULL,
	"association_id" bigint NOT NULL,
	"assigned_by" bigint,
	"assigned_at" timestamp with time zone DEFAULT now(),
	"effective_from" timestamp with time zone DEFAULT now(),
	"effective_to" timestamp with time zone,
	"status" varchar(20) DEFAULT 'PENDING',
	"approved_by" bigint,
	"approved_at" timestamp with time zone,
	CONSTRAINT "taxi_route_assignments_status_check" CHECK ("taxi_route_assignments"."status" IN ('PENDING', 'ACTIVE', 'REJECTED', 'CANCELLED', 'COMPLETED')),
	CONSTRAINT "taxi_route_assignments_effective_period_check" CHECK ("taxi_route_assignments"."effective_to" IS NULL OR "taxi_route_assignments"."effective_to" > "taxi_route_assignments"."effective_from")
);
--> statement-breakpoint
CREATE TABLE "taxis" (
	"taxi_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "taxis_taxi_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"plate_number" varchar(30) NOT NULL,
	"vehicle_type" varchar(50),
	"seating_capacity" integer,
	"association_id" bigint,
	"driver_id" bigint,
	"registration_date" date DEFAULT CURRENT_DATE,
	"status" varchar(20) DEFAULT 'ACTIVE',
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "taxis_plate_number_unique" UNIQUE("plate_number"),
	CONSTRAINT "taxis_status_check" CHECK ("taxis"."status" IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))
);
--> statement-breakpoint
CREATE TABLE "users" (
	"user_id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "users_user_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"full_name" varchar(150) NOT NULL,
	"mobile_number" varchar(20) NOT NULL,
	"password_hash" text NOT NULL,
	"role_id" bigint,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "users_mobile_number_unique" UNIQUE("mobile_number")
);
--> statement-breakpoint
ALTER TABLE "drivers" ADD CONSTRAINT "drivers_user_id_users_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "route_stages" ADD CONSTRAINT "route_stages_route_id_routes_route_id_fk" FOREIGN KEY ("route_id") REFERENCES "public"."routes"("route_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "taxi_route_assignments" ADD CONSTRAINT "taxi_route_assignments_taxi_id_taxis_taxi_id_fk" FOREIGN KEY ("taxi_id") REFERENCES "public"."taxis"("taxi_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "taxi_route_assignments" ADD CONSTRAINT "taxi_route_assignments_route_id_routes_route_id_fk" FOREIGN KEY ("route_id") REFERENCES "public"."routes"("route_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "taxi_route_assignments" ADD CONSTRAINT "taxi_route_assignments_association_id_associations_association_id_fk" FOREIGN KEY ("association_id") REFERENCES "public"."associations"("association_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "taxi_route_assignments" ADD CONSTRAINT "taxi_route_assignments_assigned_by_users_user_id_fk" FOREIGN KEY ("assigned_by") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "taxi_route_assignments" ADD CONSTRAINT "taxi_route_assignments_approved_by_users_user_id_fk" FOREIGN KEY ("approved_by") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "taxis" ADD CONSTRAINT "taxis_association_id_associations_association_id_fk" FOREIGN KEY ("association_id") REFERENCES "public"."associations"("association_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "taxis" ADD CONSTRAINT "taxis_driver_id_drivers_driver_id_fk" FOREIGN KEY ("driver_id") REFERENCES "public"."drivers"("driver_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_role_id_roles_role_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("role_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "uq_taxi_active_assignment" ON "taxi_route_assignments" USING btree ("taxi_id") WHERE "taxi_route_assignments"."status" = 'ACTIVE';