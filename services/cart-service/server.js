const express = require("express");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const { connectDB } = require("./config/db");
const CartItem = require("./models/CartItem");
const client = require("prom-client");

const app = express();

app.use(cors());
app.use(express.json());


const collectDefaultMetrics = client.collectDefaultMetrics;

collectDefaultMetrics();

//getting carts-service metrics

app.get("/api/cart/metrics", async (req, res) => {
  res.set("Content-Type", client.register.contentType);

  res.end(await client.register.metrics());
});






// auth middleware
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ message: "No token provided" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET );
    req.user = decoded;
    next();
  } catch {
    return res.status(401).json({ message: "Invalid token" });
  }
};

// connecting to the db

const startServer = async () => {

  await connectDB();

  await CartItem.sync();

  console.log("CartItems table created");

  app.listen(3001, () => {
    console.log("Cart Service running on port 3001");
  });

};

startServer();


app.get("/api/cart/health", (req, res) => {
  res.status(200).send("OK");
});


// test route
app.get("/cart", (req, res) => {
  res.send("Cart Service running");
});

// add to cart
app.post("/api/cart/add", authMiddleware, async (req, res) => {

  try {

    const email = req.user.email;

    const { product } = req.body;

    await CartItem.create({

      userEmail: email,

      productId: product.id,

      productName: product.name,

      price: product.price

    });

    res.json({ message: "Added to cart" });

  } catch (error) {

    console.log(error);

    res.status(500).json({
      message: "Server error"
    });
  }
});







// get cart
app.get("/api/cart", authMiddleware, async (req, res) => {

  try {

    const email = req.user.email;

    const cartItems = await CartItem.findAll({

      where: {
        userEmail: email
      }

    });

    res.json({
      cart: cartItems
    });

  } catch (error) {

    console.log(error);

    res.status(500).json({
      message: "Server error"
    });
  }
});


