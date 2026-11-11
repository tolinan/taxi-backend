import express from "express";
import { pool } from "./db/index.js";

const app = express();
const port = 8000;

app.use(express.json());

app.get("/", (_request, response) => {
  response.send("Taxi API is running");
});

const startServer = async () => {
  try {
    await pool.connect();
    console.log("Connected to PostgreSQL");
    app.listen(port, () => {
      console.log(`Server is running on http://localhost:${port}`);
    });
  } catch (error) {
    console.error("Failed to connect to PostgreSQL:", error);
    await pool.end();
    process.exitCode = 1;
  }
};

void startServer();