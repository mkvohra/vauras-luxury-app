import { Link } from "react-router-dom";

function Navbar() {
  return (
    <nav style={{
      display: "flex",
      justifyContent: "space-between",
      padding: "15px 30px",
      backgroundColor: "#111",
      color: "white"
    }}>
      <div>LuxeBags</div>

      <div style={{ display: "flex", gap: "20px" }}>
        <Link to="/">Home</Link>
        <Link to="/login">Login</Link>

        <Link to="/signup" style={{
          backgroundColor: "white",
          color: "black",
          padding: "5px 10px",
          borderRadius: "5px"
        }}>
          Sign Up
        </Link>
        <Link to="/shop">Shop</Link>
        <Link to="/wishlist">Wishlist</Link>
        <Link to="/cart">Cart</Link>
      </div>
    </nav>
  );
}

export default Navbar;