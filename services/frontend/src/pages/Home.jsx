import { useState, useEffect } from "react";
import ProductCard from "../components/ProductCard";
import toteImg from "../assets/images/tote.jpg";
import crossbodyImg from "../assets/images/crossbody.jpg";
import clutchImg from "../assets/images/clutch.jpg";
import shoulderImg from "../assets/images/shoulder.jpg";
import handImg from "../assets/images/handbag.jpg";
import { API_BASE_URL } from "../config/api";


function Home() {
  const [products, setProducts] = useState([]);

  useEffect(() => {
    setTimeout(() => {
      const data = [
        {
          id: 1,
          name: "Italian Leather Tote",
          price: 8999,
          image: toteImg
        },

        {
          id: 2,
          name: "Designer Crossbody",
          price: 6499,
          image: crossbodyImg
        },

        {
          id: 3,
          name: "Elegant Clutch",
          price: 4999,
          image: clutchImg
        },

        {
          id: 4,
          name: "Classic Shoulder Bag",
          price: 7299,
          image: shoulderImg
        },

        {
          id: 5,
          name: "Hand bag",
          price: 9999,
          image: handImg
        }
      ];

      setProducts(data);
    }, 1000);
  }, []);

  // 🔥 ADD TO CART LOGIC HERE
  const handleAddToCart = async (product) => {
    const token = localStorage.getItem("token");

    await fetch(`${API_BASE_URL}/api/cart/add`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
      },
      body: JSON.stringify({ product })
    });

    alert("Added to cart!");
  };

  return (
    <div>
      <section style={{ padding: "60px", textAlign: "center" }}>
        <h1>Timeless Luxury. Modern Craft.</h1>
        <p>Discover premium handbags curated for elegance.</p>
      </section>

      <section style={{ padding: "40px" }}>
        <h2 style={{ textAlign: "center" }}>Featured Products</h2>

        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          gap: "20px",
          marginTop: "30px"
        }}>
          {products.length === 0 ? (
            <p>Loading...</p>
          ) : (
            products.map((product) => (
              <ProductCard
                key={product.id}
                product={product}
                onAddToCart={handleAddToCart}
              />
            ))
          )}
        </div>
      </section>
    </div>
  );
}

export default Home;