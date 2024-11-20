import { Redis } from "ioredis";
import express from "express";

let redis: Redis | null = null;
const expressPort = 3000;

const getRedis = () => {
  if (redis == null) {
    redis = new Redis(6379, "redis-local");
  }
  return redis;
};

const server = express();

server.get("/ping", (req, res) => {
  res.json({ ping: "pong" });
});

server.get("/set/:key/:value", async (req, res) => {
  const { key, value } = req.params;
  await getRedis().set(key, value);
  res.json({
    ok: true,
    message: `set ${key} to ${value}`,
  });
});

server.get("/get/:key", async (req, res) => {
  const value = await getRedis().get(req.params.key);
  res.json({
    [req.params.key]: value,
  });
});

function main() {
  server.listen(expressPort, "0.0.0.0", () => {
    console.log(`Server listening at port ${expressPort}`);
  });
}

main();
