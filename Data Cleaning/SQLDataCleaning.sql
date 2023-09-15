SELECT * 
FROM SQLDataCleaning.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------
-- Change Date Column Format to Date 

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM SQLDataCleaning..NashvilleHousing


Update NashvilleHousing							-- Works not everytime
SET SaleDate = CONVERT(Date, SaleDate)			


ALTER TABLE NashvilleHousing					-- This is an alternative method
ADD SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted
FROM SQLDataCleaning..NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------
-- If there is no address for an entry, it searches over the column ParcelID 
-- whether there is an entry which has an address and then copies the address to the missing address field
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) --ISNULL is the command that does the task, but here we are just checking if everything went correctely
FROM SQLDataCleaning..NashvilleHousing a
JOIN SQLDataCleaning..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is NULL

Update a														-- via the update function we make the corresponding changes
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM SQLDataCleaning..NashvilleHousing a
JOIN SQLDataCleaning..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is NULL


--------------------------------------------------------------------------------------------------------------------------------
-- Seperating Address Column into individual columns (Address, State, City)
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address						-- the 1 in SUBSTRING means, that it starts searching for the character at the very frist string in every entry
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address  -- since CHARINDEX returns a position within the string one can handle it like the positioning in an array
FROM SQLDataCleaning..NashvilleHousing


ALTER TABLE NashvilleHousing																		-- adds new column	
ADD PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)		-- updates table


ALTER TABLE NashvilleHousing																		-- adds new column	
ADD PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))	-- updates table



SELECT																-- Since PARSENAME does things backward, one has to change the order 
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)						-- so except 1,2,3 we need to use 3,2,1
, PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM SQLDataCleaning..NashvilleHousing


ALTER TABLE NashvilleHousing																		-- adds new column	
ADD OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)	-- updates table


ALTER TABLE NashvilleHousing																		-- adds new column	
ADD OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)	-- updates table


ALTER TABLE NashvilleHousing																		-- adds new column	
ADD OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)		-- updates table


--------------------------------------------------------------------------------------------------------------------------------
-- Since in the column "SoldAsVacant" has different variations of Yes/Y/No/N the task is now to standardize

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN ' Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM SQLDataCleaning..NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant  = CASE WHEN SoldAsVacant = 'Y' THEN ' Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


--------------------------------------------------------------------------------------------------------------------------------
-- Remove duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM SQLDataCleaning.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


--------------------------------------------------------------------------------------------------------------------------------
-- Delete unsued columns

ALTER TABLE SQLDataCleaning.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
