import { useEffect, useState } from "react";
import { API_BASE_URL } from "../config/api";

function Cart() {
  const [cart, setCart] = useState([]);

  useEffect(() => {
    const fetchCart = async () => {
      const token = localStorage.getItem("token");

      const res = await fetch(`${API_BASE_URL}/api/cart`, {
        headers: {
          "Authorization": `Bearer ${token}`
        }
      });

      const data = await res.json();
      setCart(data.cart);
    };

    fetchCart();
  }, []);

  return (
    <div style={{ padding: "40px" }}>
      <h1>Your Cart</h1>

      {cart.length === 0 ? (
        <p>No items in cart</p>
      ) : (
        cart.map((item, index) => (
          <div key={index}>
            {item.productName} - ₹{item.price}
          </div>
        ))
      )}
    </div>
  );
}

export default Cart;