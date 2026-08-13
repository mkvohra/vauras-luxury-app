const express = require("express");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const { connectDB } = require("./config/db");
const User = require("./models/User");
const bcrypt = require("bcrypt");
const client = require("prom-client");

const app = express();

app.use(cors());
app.use(express.json());


const collectDefaultMetrics = client.collectDefaultMetrics;

collectDefaultMetrics();


//getting auth-service metrics
app.get("/api/auth/metrics", async (req, res) => {
  res.set("Content-Type", client.register.contentType);

  res.end(await client.register.metrics());
});




// connecting to db

//connectDB();


// auto creating table and connecting to db
const startServer = async () => {
  await connectDB();

  // create tables
  await User.sync();

  app.listen(3000, () => {
    console.log("Server running on port 3000");
  });
};

startServer();





app.get("/api/auth/health", (req, res) => {
  res.status(200).send("OK");
});


// test route
app.get("/", (req, res) => {
  res.send("Auth Service is running and hello from docker!!");
});







// signup

app.post("/api/auth/signup", async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // check if user already exists
    const existingUser = await User.findOne({
      where: { email }
    });

    if (existingUser) {
      return res.status(400).json({
        message: "User already exists"
      });
    }

    // hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // create user
    await User.create({
      name,
      email,
      password: hashedPassword
    });

    res.json({
      message: "User created successfully"
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Server error"
    });
  }
});









// login
app.post("/api/auth/login", async (req, res) => {
  try {

    const { email, password } = req.body;

    // find user in DB
    const user = await User.findOne({
      where: { email }
    });

    // user not found
    if (!user) {
      return res.status(400).json({
        message: "User not found"
      });
    }

    // compare password with hash
    const isMatch = await bcrypt.compare(
      password,
      user.password
    );

    // invalid password
    if (!isMatch) {
      return res.status(400).json({
        message: "Invalid password"
      });
    }

    // generate JWT
    const token = jwt.sign(
      { email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    res.json({ token });

  } catch (error) {

    console.error(error);

    res.status(500).json({
      message: "Server error"
    });
  }
});