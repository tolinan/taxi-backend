import "dotenv/config";
import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import * as schema from "./schema.js";

export const pool = new Pool({
  connectionTimeoutMillis: 5000,
});

export const db = drizzle(pool, { schema });
