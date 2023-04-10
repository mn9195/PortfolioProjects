/*

Cleaning Data with SQL Queries

*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- STANDARDIZE DATA FORMAT (We are Adding a column SaleDateConverted = the SaleDate which is basically Datetime type to Date)

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- POPULATE PROPERTY ADDRESS DATA

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
--We can see here that there are NULL Values in Property Address
SELECT *
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID
-- We can see here that the ParcelID can be duplicated and have the same PropertyAddress. So let's replace it By ParcelID
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousing AS A
JOIN NashvilleHousing AS B
    ON A.ParcelID = B.ParcelID
    AND A.UniqueID != B.UniqueID
WHERE A.PropertyAddress IS NULL

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousing AS A
JOIN NashvilleHousing AS B
    ON A.ParcelID = B.ParcelID
    AND A.UniqueID != B.UniqueID
WHERE A.PropertyAddress IS NULL

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

-- Here, th sbutstring allows to substract an string and CHARINDEX allows to have the index of a given element (here the '.'). The -1 is to substract the '.'
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX('.', PropertyAddress) -1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX('.', PropertyAddress) +2, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

-- Now let's create the columns and fill it with the Address and Cities separated
ALTER TABLE NashvilleHousing
ADD Address2 NVARCHAR(255);

UPDATE NashvilleHousing
SET Address2 = SUBSTRING(PropertyAddress, 1, CHARINDEX('.', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD City NVARCHAR(255);

UPDATE NashvilleHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX('.', PropertyAddress) +2, LEN(PropertyAddress))

SELECT *
FROM NashvilleHousing

-- Now let's focus on the Owners Address
SELECT OwnerAddress
FROM NashvilleHousing
-- PARSENAME only works with '.', if it was ',' we had to replace it that way : REPLACE(OwnerAddress, ',', '.')
SELECT 
    PARSENAME(OwnerAddress, 3),
    PARSENAME(OwnerAddress, 2),
    PARSENAME(OwnerAddress, 1)
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerAddress2 NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerAddress2 = PARSENAME(OwnerAddress, 3)

ALTER TABLE NashvilleHousing
ADD OwnerCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(OwnerAddress, 2)

ALTER TABLE NashvilleHousing
ADD OwnerState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(OwnerAddress, 1)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CHANGE THE Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD

SELECT DISTINCT SoldAsVacant
FROM NashvilleHousing

SELECT 
    SoldAsVacant,
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM NashvilleHousing
WHERE SoldAsVacant = 'N' OR SoldAsVacant = 'Y'

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- REMOVE DUPLICATES

-- Let's take ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference as references (if these elements are the same then for multiple time, let's delete them)
-- Let's put the function into a CTE (so we can apply function like WHERE on it)
WITH RowNumCTE AS (
SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                ORDER BY
                    UniqueID
    ) AS row_num
FROM NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1

-- So as we can see, there are 104 duplicated rows. Let's delete them
DELETE
FROM RowNumCTE
WHERE row_num > 1

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--DELETE UNUSED COLUMNS
-- Let's delete the unsed columns that we have

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

SELECT *
FROM NashvilleHousing