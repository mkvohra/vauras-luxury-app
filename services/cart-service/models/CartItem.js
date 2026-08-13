const { DataTypes } = require("sequelize");

const { sequelize } = require("../config/db");

const CartItem = sequelize.define("CartItem", {

  userEmail: {
    type: DataTypes.STRING,
    allowNull: false
  },

  productId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },

  productName: {
    type: DataTypes.STRING,
    allowNull: false
  },

  price: {
    type: DataTypes.STRING,
    allowNull: false
  }

});

module.exports = CartItem;