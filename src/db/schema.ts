import {
  bigint,
  boolean,
  check,
  date,
  foreignKey,
  integer,
  inet,
  jsonb,
  numeric,
  pgTable,
  text,
  timestamp,
  unique,
  uniqueIndex,
  uuid,
  varchar,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

export const roles = pgTable("roles", {
  roleId: bigint("role_id", { mode: "number" }).generatedAlwaysAsIdentity().primaryKey(),
  roleName: varchar("role_name", { length: 50 }).notNull().unique(),
  description: text("description"),
});

export const users = pgTable("users", {
  userId: bigint("user_id", { mode: "number" }).generatedAlwaysAsIdentity().primaryKey(),
  fullName: varchar("full_name", { length: 150 }).notNull(),
  mobileNumber: varchar("mobile_number", { length: 20 }).notNull().unique(),
  passwordHash: text("password_hash").notNull(),
  roleId: bigint("role_id", { mode: "number" }).references(() => roles.roleId),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
});

export const associations = pgTable(
  "associations",
  {
    associationId: bigint("association_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    associationName: varchar("association_name", { length: 150 }).notNull(),
    registrationNumber: varchar("registration_number", { length: 50 }).unique(),
    contactPerson: varchar("contact_person", { length: 150 }),
    mobileNumber: varchar("mobile_number", { length: 20 }),
    address: text("address"),
    status: varchar("status", { length: 20 }).default("ACTIVE"),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  },
  (table) => [
    check(
      "associations_status_check",
      sql`${table.status} IN ('ACTIVE', 'INACTIVE')`,
    ),
  ],
);

export const drivers = pgTable(
  "drivers",
  {
    driverId: bigint("driver_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    userId: bigint("user_id", { mode: "number" }).references(() => users.userId),
    fullName: varchar("full_name", { length: 150 }).notNull(),
    mobileNumber: varchar("mobile_number", { length: 20 }).notNull().unique(),
    licenseNumber: varchar("license_number", { length: 50 }).unique(),
    licenseExpiry: date("license_expiry"),
    status: varchar("status", { length: 20 }).default("ACTIVE"),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  },
  (table) => [
    check(
      "drivers_status_check",
      sql`${table.status} IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')`,
    ),
  ],
);

export const taxis = pgTable(
  "taxis",
  {
    taxiId: bigint("taxi_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    plateNumber: varchar("plate_number", { length: 30 }).notNull().unique(),
    vehicleType: varchar("vehicle_type", { length: 50 }),
    seatingCapacity: integer("seating_capacity"),
    associationId: bigint("association_id", { mode: "number" }).references(
      () => associations.associationId,
    ),
    driverId: bigint("driver_id", { mode: "number" }).references(
      () => drivers.driverId,
    ),
    registrationDate: date("registration_date").default(sql`CURRENT_DATE`),
    status: varchar("status", { length: 20 }).default("ACTIVE"),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  },
  (table) => [
    check(
      "taxis_status_check",
      sql`${table.status} IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')`,
    ),
  ],
);

export const routes = pgTable(
  "routes",
  {
    routeId: bigint("route_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    routeName: varchar("route_name", { length: 150 }).notNull(),
    startPoint: varchar("start_point", { length: 150 }).notNull(),
    endPoint: varchar("end_point", { length: 150 }).notNull(),
    totalDistanceKm: numeric("total_distance_km", {
      precision: 10,
      scale: 2,
    }).notNull(),
    status: varchar("status", { length: 20 }).default("ACTIVE"),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  },
  (table) => [
    check(
      "routes_status_check",
      sql`${table.status} IN ('ACTIVE', 'INACTIVE')`,
    ),
  ],
);

export const routeStages = pgTable(
  "route_stages",
  {
    stageId: bigint("stage_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    routeId: bigint("route_id", { mode: "number" })
      .notNull()
      .references(() => routes.routeId),
    stageName: varchar("stage_name", { length: 150 }).notNull(),
    stageOrder: integer("stage_order").notNull(),
    distanceFromStartKm: numeric("distance_from_start_km", {
      precision: 10,
      scale: 2,
    }).notNull(),
  },
  (table) => [
    unique("route_stages_route_order_unique").on(table.routeId, table.stageOrder),
    unique("route_stages_route_stage_unique").on(table.routeId, table.stageId),
  ],
);

export const taxiRouteAssignments = pgTable(
  "taxi_route_assignments",
  {
    assignmentId: bigint("assignment_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    taxiId: bigint("taxi_id", { mode: "number" })
      .notNull()
      .references(() => taxis.taxiId),
    routeId: bigint("route_id", { mode: "number" })
      .notNull()
      .references(() => routes.routeId),
    associationId: bigint("association_id", { mode: "number" })
      .notNull()
      .references(() => associations.associationId),
    assignedBy: bigint("assigned_by", { mode: "number" }).references(
      () => users.userId,
    ),
    assignedAt: timestamp("assigned_at", { withTimezone: true }).defaultNow(),
    effectiveFrom: timestamp("effective_from", { withTimezone: true }).defaultNow(),
    effectiveTo: timestamp("effective_to", { withTimezone: true }),
    status: varchar("status", { length: 20 }).default("PENDING"),
    approvedBy: bigint("approved_by", { mode: "number" }).references(
      () => users.userId,
    ),
    approvedAt: timestamp("approved_at", { withTimezone: true }),
  },
  (table) => [
    check(
      "taxi_route_assignments_status_check",
      sql`${table.status} IN ('PENDING', 'ACTIVE', 'REJECTED', 'CANCELLED', 'COMPLETED')`,
    ),
    check(
      "taxi_route_assignments_effective_period_check",
      sql`${table.effectiveTo} IS NULL OR ${table.effectiveTo} > ${table.effectiveFrom}`,
    ),
    uniqueIndex("uq_taxi_active_assignment")
      .on(table.taxiId)
      .where(sql`${table.status} = 'ACTIVE'`),
  ],
);

export const tariffs = pgTable(
  "tariffs",
  {
    tariffId: bigint("tariff_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    tariffName: varchar("tariff_name", { length: 100 }).notNull(),
    tariffPerKm: numeric("tariff_per_km", { precision: 10, scale: 2 }).notNull(),
    minimumFare: numeric("minimum_fare", { precision: 10, scale: 2 }).default("0"),
    effectiveFrom: timestamp("effective_from", { withTimezone: true }).notNull(),
    effectiveTo: timestamp("effective_to", { withTimezone: true }),
    status: varchar("status", { length: 20 }).default("PENDING"),
    createdBy: bigint("created_by", { mode: "number" }).references(() => users.userId),
    approvedBy: bigint("approved_by", { mode: "number" }).references(() => users.userId),
    approvedAt: timestamp("approved_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  },
  (table) => [
    check(
      "tariffs_status_check",
      sql`${table.status} IN ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED')`,
    ),
    check("tariffs_tariff_per_km_check", sql`${table.tariffPerKm} > 0`),
    check("tariffs_minimum_fare_check", sql`${table.minimumFare} >= 0`),
    check(
      "tariffs_effective_period_check",
      sql`${table.effectiveTo} IS NULL OR ${table.effectiveTo} > ${table.effectiveFrom}`,
    ),
  ],
);

export const qrCodes = pgTable(
  "qr_codes",
  {
    qrId: bigint("qr_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    taxiId: bigint("taxi_id", { mode: "number" })
      .notNull()
      .references(() => taxis.taxiId),
    assignmentId: bigint("assignment_id", { mode: "number" })
      .notNull()
      .references(() => taxiRouteAssignments.assignmentId),
    qrTokenHash: text("qr_token_hash").notNull().unique(),
    generatedAt: timestamp("generated_at", { withTimezone: true }).defaultNow(),
    expiresAt: timestamp("expires_at", { withTimezone: true }),
    status: varchar("status", { length: 20 }).default("ACTIVE"),
  },
  (table) => [
    check(
      "qr_codes_status_check",
      sql`${table.status} IN ('ACTIVE', 'REVOKED', 'EXPIRED')`,
    ),
  ],
);

export const commuters = pgTable("commuters", {
  commuterId: bigint("commuter_id", { mode: "number" })
    .generatedAlwaysAsIdentity()
    .primaryKey(),
  userId: bigint("user_id", { mode: "number" }).references(() => users.userId),
  fullName: varchar("full_name", { length: 150 }),
  mobileNumber: varchar("mobile_number", { length: 20 }),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
});

export const transactions = pgTable(
  "transactions",
  {
    transactionId: bigint("transaction_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    transactionReference: uuid("transaction_reference").notNull().defaultRandom().unique(),
    commuterId: bigint("commuter_id", { mode: "number" }).references(
      () => commuters.commuterId,
    ),
    taxiId: bigint("taxi_id", { mode: "number" })
      .notNull()
      .references(() => taxis.taxiId),
    assignmentId: bigint("assignment_id", { mode: "number" })
      .notNull()
      .references(() => taxiRouteAssignments.assignmentId),
    qrId: bigint("qr_id", { mode: "number" }).references(() => qrCodes.qrId),
    routeId: bigint("route_id", { mode: "number" })
      .notNull()
      .references(() => routes.routeId),
    boardingStageId: bigint("boarding_stage_id", { mode: "number" }).notNull(),
    destinationStageId: bigint("destination_stage_id", { mode: "number" }).notNull(),
    distanceKm: numeric("distance_km", { precision: 10, scale: 2 }).notNull(),
    tariffId: bigint("tariff_id", { mode: "number" })
      .notNull()
      .references(() => tariffs.tariffId),
    appliedTariffPerKm: numeric("applied_tariff_per_km", {
      precision: 10,
      scale: 2,
    }).notNull(),
    fareAmount: numeric("fare_amount", { precision: 12, scale: 2 }).notNull(),
    paymentMethod: varchar("payment_method", { length: 30 }).default("TELEBIRR"),
    telebirrReference: varchar("telebirr_reference", { length: 150 }).unique(),
    paymentStatus: varchar("payment_status", { length: 20 }).default("PENDING"),
    paymentInitiatedAt: timestamp("payment_initiated_at", {
      withTimezone: true,
    }).defaultNow(),
    paymentCompletedAt: timestamp("payment_completed_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  },
  (table) => [
    foreignKey({
      name: "transactions_boarding_stage_fk",
      columns: [table.routeId, table.boardingStageId],
      foreignColumns: [routeStages.routeId, routeStages.stageId],
    }),
    foreignKey({
      name: "transactions_destination_stage_fk",
      columns: [table.routeId, table.destinationStageId],
      foreignColumns: [routeStages.routeId, routeStages.stageId],
    }),
    check(
      "transactions_payment_status_check",
      sql`${table.paymentStatus} IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED', 'REFUNDED', 'PARTIALLY_REFUNDED')`,
    ),
    check("transactions_distance_check", sql`${table.distanceKm} > 0`),
    check("transactions_fare_amount_check", sql`${table.fareAmount} > 0`),
    check(
      "transactions_applied_tariff_check",
      sql`${table.appliedTariffPerKm} > 0`,
    ),
    check(
      "transactions_stage_difference_check",
      sql`${table.boardingStageId} <> ${table.destinationStageId}`,
    ),
  ],
);

export const paymentCallbacks = pgTable(
  "payment_callbacks",
  {
    callbackId: bigint("callback_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    transactionId: bigint("transaction_id", { mode: "number" }).references(
      () => transactions.transactionId,
    ),
    providerReference: varchar("provider_reference", { length: 150 }),
    callbackPayload: jsonb("callback_payload"),
    verificationStatus: varchar("verification_status", { length: 20 }).default(
      "PENDING",
    ),
    receivedAt: timestamp("received_at", { withTimezone: true }).defaultNow(),
    processedAt: timestamp("processed_at", { withTimezone: true }),
  },
  (table) => [
    check(
      "payment_callbacks_verification_status_check",
      sql`${table.verificationStatus} IN ('PENDING', 'VERIFIED', 'REJECTED')`,
    ),
  ],
);

export const receipts = pgTable("receipts", {
  receiptId: bigint("receipt_id", { mode: "number" })
    .generatedAlwaysAsIdentity()
    .primaryKey(),
  transactionId: bigint("transaction_id", { mode: "number" })
    .notNull()
    .unique()
    .references(() => transactions.transactionId),
  receiptNumber: varchar("receipt_number", { length: 100 }).notNull().unique(),
  issuedAt: timestamp("issued_at", { withTimezone: true }).defaultNow(),
});

export const refunds = pgTable(
  "refunds",
  {
    refundId: bigint("refund_id", { mode: "number" })
      .generatedAlwaysAsIdentity()
      .primaryKey(),
    transactionId: bigint("transaction_id", { mode: "number" })
      .notNull()
      .references(() => transactions.transactionId),
    refundReference: varchar("refund_reference", { length: 150 })
      .notNull()
      .unique(),
    refundAmount: numeric("refund_amount", { precision: 12, scale: 2 }).notNull(),
    reason: text("reason"),
    status: varchar("status", { length: 20 }).default("PENDING"),
    requestedBy: bigint("requested_by", { mode: "number" }).references(
      () => users.userId,
    ),
    approvedBy: bigint("approved_by", { mode: "number" }).references(
      () => users.userId,
    ),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  },
  (table) => [
    check(
      "refunds_status_check",
      sql`${table.status} IN ('PENDING', 'APPROVED', 'REJECTED', 'SUCCESS', 'FAILED')`,
    ),
    check("refunds_refund_amount_check", sql`${table.refundAmount} > 0`),
  ],
);

export const auditLogs = pgTable("audit_logs", {
  auditId: bigint("audit_id", { mode: "number" })
    .generatedAlwaysAsIdentity()
    .primaryKey(),
  userId: bigint("user_id", { mode: "number" }).references(() => users.userId),
  action: varchar("action", { length: 100 }).notNull(),
  tableName: varchar("table_name", { length: 100 }),
  recordId: bigint("record_id", { mode: "number" }),
  oldValues: jsonb("old_values"),
  newValues: jsonb("new_values"),
  ipAddress: inet("ip_address"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
});
