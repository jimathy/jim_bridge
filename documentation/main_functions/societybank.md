### societybank.lua

This module handles financial operations for society accounts, typically used for jobs or organizations.

- **getSocietyAccount(society)**

  - Retrieves the current balance for the specified society.
  - **Example:**
    ```lua
    local balance = getSocietyAccount("police")
    print("Police account balance: $"..balance)
    ```

- **chargeSociety(society, amount)**

  - Deducts a specified amount from the society's account.
  - **Example:**
    ```lua
    chargeSociety("police", 500)
    ```

- **fundSociety(society, amount)**

  - Adds funds to a society’s account.
  - **Example:**
    ```lua
    fundSociety("ambulance", 1200)
    ```
