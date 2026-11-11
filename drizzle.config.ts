import "dotenv/config";
import { defineConfig } from "drizzle-kit";

const databaseUrl =
  process.env.DATABASE_URL ??
  `postgres://${encodeURIComponent(process.env.PGUSER ?? "postgres")}:${encodeURIComponent(
    process.env.PGPASSWORD ?? "",
  )}@${process.env.PGHOST ?? "localhost"}:${process.env.PGPORT ?? "5432"}/${
    process.env.PGDATABASE ?? "postgres"
  }`;

export default defineConfig({
  dialect: "postgresql",
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dbCredentials: { url: databaseUrl },
});
