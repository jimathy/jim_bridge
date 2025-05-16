### drawText.lua

These functions handle drawing and hiding styled on-screen prompts or UI overlays, compatible with different styling frameworks such as OX Lib.

- **drawText(image, input, style, oxStyleTable)**

  - Displays styled text or prompts on screen.
  - Designed to adapt styling depending on which UI system (e.g., OX) is in use.
  - **Parameters:**
    - `image` (`string`): Optional icon or image path.
    - `input` (`string`): The main text to display.
    - `style` (`string|table`): Preset or custom styling.
    - `oxStyleTable` (`table`, optional): Extended style options if using OX UI.
  - **Example:**
    ```lua
    drawText("img_link", { "Test line 1", "Test Line 2" }, "~g~")
    ```

- **hideText()**

  - Hides any active text or UI element previously drawn with `drawText()`.
  - **Example:**
    ```lua
    hideText()
    ```
