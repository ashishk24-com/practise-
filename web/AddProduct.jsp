<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.nio.file.Files" %>
<%@ page import="java.io.*" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.servlet.*" %>
<%@ page import="javax.servlet.http.*" %>

<%
    HttpSession httpSession = request.getSession();
    String guid = (String) httpSession.getAttribute("currentuser");

    String prname = request.getParameter("prname");
    String prid = request.getParameter("prid");
    String mfname = request.getParameter("mfname");
    String mdate = request.getParameter("mdate");
    String edate = request.getParameter("edate");
    String quantity = request.getParameter("quantity");
    String price = request.getParameter("price");
    String path = request.getParameter("product_image");
    Part filePart = request.getPart("product_image");
    
    // Initialize variables to hold parsed integer values
    int p = 0;
    int q = 0;

    // Database queries
    String query1 = "SELECT pid FROM product WHERE pid=?";
    String query2 = "INSERT INTO product(pid, pname, manufacturer, mfg, exp, price, image_path) VALUES (?, ?, ?, ?, ?, ?, ?)";
    String query3 = "INSERT INTO inventory(pid, pname, sid, quantity) VALUES (?, ?, ?, ?)";

    // Database objects
    ResultSet rs = null;
    Connection conn = null;
    PreparedStatement ps1 = null;
    PreparedStatement ps2 = null;
    PreparedStatement ps3 = null;

    try {
        // Database connection
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/agro", "root", "Yadav@123");

        // Check if product ID is provided
        if (prid == null || prid.isEmpty()) {
            // Redirect back to the form with an error message
            response.sendRedirect("AddProduct.jsp?error=pid_required");
        } else {
            // Check if product ID already exists
            ps1 = conn.prepareStatement(query1);
            ps1.setString(1, prid);
            rs = ps1.executeQuery();
            
            // If product ID doesn't exist, insert product details and move image file
            if (!rs.next()) {
                // Parse price and quantity if they are not null or empty
                if (price != null && !price.isEmpty()) {
                    p = Integer.parseInt(price);
                }
                if (quantity != null && !quantity.isEmpty()) {
                    q = Integer.parseInt(quantity);
                }

                // Insert product details
                ps2 = conn.prepareStatement(query2);
                ps2.setString(1, prid);
                ps2.setString(2, prname);
                ps2.setString(3, mfname);
                ps2.setString(4, mdate);
                ps2.setString(5, edate);
                ps2.setInt(6, p);

                // Get image file details
                String fileName = null;
                if (filePart != null) {
                    fileName = filePart.getSubmittedFileName();
                    String fullFilePath = getServletContext().getRealPath("") + File.separator + "uploads" + File.separator + fileName;
                    
                    // Move image file to uploads folder
                    try (InputStream input = filePart.getInputStream()) {
                        Files.copy(input, new File(fullFilePath).toPath());
                    }

                    // Insert image path into the database
                    ps2.setString(7, path);
                }

                // Execute product insertion query
                int i = ps2.executeUpdate();

                // Insert inventory details
                ps3 = conn.prepareStatement(query3);
                ps3.setString(1, prid);
                ps3.setString(2, prname);
                ps3.setString(3, guid);
                ps3.setInt(4, q);
                int j = ps3.executeUpdate();

                // Redirect to AddInventory.jsp after successful insertion
                response.sendRedirect("AddInventory.jsp");
            } else {
                // Redirect to error page if product ID already exists
                response.sendRedirect("AddProductError.html");
            }
        }
    } catch (NumberFormatException e) {
        // Redirect to error page if price or quantity cannot be parsed to integer
        response.sendRedirect("AddProductError2.html");
        e.printStackTrace();
    } catch (Exception e) {
        // Redirect to error page if any other exception occurs
        response.sendRedirect("AddProductError2.html");
        e.printStackTrace();
    } finally {
        // Close all resources
        try {
            if (rs != null) rs.close();
            if (ps1 != null) ps1.close();
            if (ps2 != null) ps2.close();
            if (ps3 != null) ps3.close();
            if (conn != null) conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
%>
