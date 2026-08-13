function ProductCard({ product, onAddToCart }) {
  return (
    <div style={{
      border: "1px solid #ddd",
      padding: "20px",
      textAlign: "center"
    }}>
      <img
        src={product.image}
        alt={product.name}
        style={{
          width: "100%",
          height: "250px",
          objectFit: "cover",
          marginBottom: "10px",
          borderRadius: "10px"
        }}
      />

      <h3>{product.name}</h3>
      <p>₹{product.price}</p>

      <button onClick={() => onAddToCart(product)}>
        Add to Cart
      </button>

      <br /><br />

      <button>
        ❤️ view cart
      </button>
    </div>
  );
}

export default ProductCard;