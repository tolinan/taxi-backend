import express from "express";

const app = express();
const port = 8000;

app.use(express.json());

app.get("/", (_request, response) => {
  response.send("Taxi API is running");
});

app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});