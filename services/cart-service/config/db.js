const { Sequelize } = require("sequelize");

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    dialect: "postgres"
  }
);

// test connection
async function connectDB(retries = 5) {
  while (retries) {
    try {
      await sequelize.authenticate();
      console.log("Cart Service connected to postgres");
      break;
    } catch (error) {
      console.log("DB not ready, retrying in 5 seconds...");
      retries--;
      await new Promise(res => setTimeout(res, 5000));
    }
  }

  if (!retries) {
    console.error("Could not connect to DB after retries");
  }
}



module.exports = {
  sequelize,
  connectDB
};