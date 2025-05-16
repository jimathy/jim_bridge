### duifunctions.lua

These functions support dynamic UI image rendering in 3D environments using runtime texture dictionaries. Ideal for integrating `nui://` or external `http://` image URLs into MLOs or world props.

- **createDui(name, http, size, txd))**

  - Sets up a runtime texture dictionary and links an image from a `nui://` or `http://` URL.
  - This function should be used once to create the texture dictionary needed for rendering Dui images.
  - **Example:**
    ```lua
    createDui("logo", "https://example.com/logo.png", { x = 512, y = 256 }, scriptTxd)
    ```

- **DuiSelect(data)**

  - Updates the URL on an existing texture dictionary to change the rendered image.
  - Can be used at runtime to swap out visuals in MLOs or props.
  - **Parameters:**
    - `textureDict` (`string`): The texture dictionary to target.
    - `texture` (`string`): The specific texture name to override.
    - `url` (`string`): The new image URL.
    - `width`, `height` (`number`): The texture resolution.
  - **Example:**
    ```lua
    DuiSelect({
        name = "logo",
        texn = "logoTex",
        texd = "someTxd",
        size = { x = 512, y = 256 }
    })
    ```
