## **SQL Data Analysis Project: Olist Dataset**

### **Project Objective**
The goal of this project was to analyze data from Olist, a Brazilian e-commerce platform, to gain insights into customer orders, payments, and reviews. Additionally, I performed an RFM (Recency, Frequency, Monetary) analysis to better understand customer behavior and identify high-value customers for targeted marketing strategies.

### **Dataset**
The project used multiple datasets from Olist’s e-commerce operations, including:
- **Customers**: Information about customers such as city, state, and zip code.
- **Order Items**: Details about individual order items, including products, sellers, prices, and shipping information.
- **Order Payments**: Information on payment methods, installments, and amounts.
- **Order Reviews**: Data on customer reviews, including review scores and comments.

### **Methods Used**
1. **RFM Analysis**:
   - Calculated **Recency** based on the most recent purchase date for each customer.
   - Calculated **Frequency** by counting the number of purchases made by each customer.
   - Calculated **Monetary** value based on total spending for each customer.
   
2. **Table Creation**:
   - Created structured tables for customers, order items, order payments, and order reviews.
   - Defined **primary keys** for unique identification and **foreign keys** to maintain relationships between tables (e.g., orders and sellers).

3. **Data Import**:
   - Imported CSV datasets into the relevant tables using the `COPY` command.

4. **Data Cleaning and Validation**:
   - Checked for duplicates and null values in the dataset to ensure data quality.

5. **SQL Aggregation**:
   - Used `COUNT` to calculate the number of unique orders and grouped payments by order ID.
   - Performed `GROUP BY` and `ORDER BY` to identify frequent payment methods and high-payment orders.

6. **Joins and Foreign Key Relationships**:
   - Used foreign keys to relate data between the `orders`, `orderitems`, `sellers`, and `orderreviews` tables.

### **Key Insights**
1. **RFM Analysis**: 
   - Identified high-value customers based on their recency, frequency, and monetary value, helping to segment customers for targeted marketing.
   
2. **Payment Methods**: 
   - The analysis identified the most common payment methods used by customers and tracked the use of installments across orders.
   
3. **Order Reviews**: 
   - Insights into customer reviews were derived by analyzing the review scores and comments, helping to understand customer satisfaction.
   
4. **Order Frequency**:
   - By counting unique orders and aggregating payments, the analysis provided insights into high-value orders and recurring customers.

### **Conclusion**
- The RFM analysis helped identify customer segments for more personalized marketing campaigns.
- The project revealed critical information about payment trends and customer satisfaction.
- Based on customer feedback (review scores), the company can improve its logistics and product quality.
- Insights into payment behavior (such as frequent use of installments) can help the business adjust its financial offerings to better serve its customer base.
