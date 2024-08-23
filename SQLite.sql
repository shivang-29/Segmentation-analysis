-- Step 1: Handle missing CustomerID by replacing with 'Unknown'
-- and filter out invalid rows

WITH CleanedData AS (
    SELECT 
        COALESCE(CustomerID, 'Unknown') AS CustomerID,  -- Replace NULL with 'Unknown'
        ProductCategory,
        CASE WHEN Quantity >= 0 THEN Quantity ELSE NULL END AS Quantity,  -- Remove negative quantities
        CASE WHEN PricePerUnit >= 0 THEN PricePerUnit ELSE NULL END AS PricePerUnit,  -- Remove negative prices
        CASE WHEN TotalAmount >= 0 THEN TotalAmount ELSE NULL END AS TotalAmount,  -- Remove negative amounts
        TrustPointsUsed
    FROM Sales
    WHERE 
        (CustomerID IS NOT NULL AND CustomerID != '')  -- Ensure CustomerID is not empty or NULL
        AND Quantity IS NOT NULL
        AND PricePerUnit IS NOT NULL
        AND TotalAmount IS NOT NULL
),
-- Step 2: Fill missing numeric fields with median (you would need a subquery for median calculation)

MedianValues AS (
    SELECT 
        (SELECT AVG(PricePerUnit) FROM CleanedData) AS MedianPricePerUnit,
        (SELECT AVG(TotalAmount) FROM CleanedData) AS MedianTotalAmount
),
-- Step 3: Apply median values where necessary

FilledData AS (
    SELECT 
        CustomerID,
        ProductCategory,
        COALESCE(Quantity, 0) AS Quantity,
        COALESCE(PricePerUnit, (SELECT MedianPricePerUnit FROM MedianValues)) AS PricePerUnit,
        COALESCE(TotalAmount, (SELECT MedianTotalAmount FROM MedianValues)) AS TotalAmount,
        COALESCE(TrustPointsUsed, 0) AS TrustPointsUsed
    FROM CleanedData
)
-- Step 4: Aggregate the data and cast TotalAmountSum to integer

SELECT 
    CustomerID, 
    ProductCategory, 
    CAST(SUM(TotalAmount) AS INT) AS TotalAmountSum,  -- Cast to integer
    SUM(Quantity) AS QuantitySum, 
    SUM(TrustPointsUsed) AS TrustPointsUsedSum
FROM FilledData
GROUP BY 
    CustomerID, 
    ProductCategory;