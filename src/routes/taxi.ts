import { and, count, eq, ilike } from "drizzle-orm";
import express from "express";
import {
  associations,
  drivers,
  routes,
  taxiRouteAssignments,
  taxis,
} from "../db/schema/schema.js";
import { db } from "../db/schema/index.js";

const router = express.Router();

router.get("/", async (req, res) => {
  try {
    const search = typeof req.query.search === "string" ? req.query.search.trim() : "";
    const requestedPage = Number(req.query.page ?? 1);
    const requestedLimit = Number(req.query.limit ?? 10);
    const currentPage = Number.isFinite(requestedPage)
      ? Math.max(1, Math.floor(requestedPage))
      : 1;
    const limitPerPage = Number.isFinite(requestedLimit)
      ? Math.max(1, Math.floor(requestedLimit))
      : 10;
    const offset = (currentPage - 1) * limitPerPage;
    const whereClause = search ? ilike(taxis.plateNumber, `%${search}%`) : undefined;

    const [taxiList, countRows] = await Promise.all([
      db
        .select({
          taxi: taxis,
          driver: drivers,
          association: associations,
          routeAssignment: taxiRouteAssignments,
          route: routes,
        })
        .from(taxis)
        .leftJoin(drivers, eq(taxis.driverId, drivers.driverId))
        .leftJoin(associations, eq(taxis.associationId, associations.associationId))
        .leftJoin(
          taxiRouteAssignments,
          and(
            eq(taxis.taxiId, taxiRouteAssignments.taxiId),
            eq(taxiRouteAssignments.status, "ACTIVE"),
          ),
        )
        .leftJoin(routes, eq(taxiRouteAssignments.routeId, routes.routeId))
        .where(whereClause)
        .limit(limitPerPage)
        .offset(offset),
      db.select({ total: count() }).from(taxis).where(whereClause),
    ]);
    const total = countRows[0]?.total;
    if (total === undefined) {
      throw new Error("Taxi count query returned no result");
    }

    res.json({
      data: taxiList,
      pagination: {
        page: currentPage,
        limit: limitPerPage,
        total,
        totalPages: Math.ceil(total / limitPerPage),
      },
    });
  } catch (error) {
    console.error("Failed to retrieve taxi information:", error);
    res.status(500).json({ error: "Failed to retrieve taxi information" });
  }
});

export default router;
