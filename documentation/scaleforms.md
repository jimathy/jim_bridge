## Scaleforms
### debugScaleform.lua
This module renders debug text in-game when `debugMode` is enabled. Useful for live diagnostics or UI placement feedback.

- **debugScaleForm(textTable, loc)**
  - Displays an overlay of lines of text at the specified screen location.
  - **Note:** This only works if `debugMode` is set to `true`.
  - **Parameters:**
    - `textTable` (`table`): A list of strings to display.
    - `loc` (`vector2`, optional): Top-left anchor point on screen (default: `vec2(0.05, 0.65)`).
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            debugScaleForm({
                "Line 1: Debug info",
                "Line 2: More info"
            })
            Wait(0)
        end
    end)
    ```

### instructionalButtons.lua
This module renders instructional button prompts using native scaleforms in GTA V and RedM.

⚠️ **Note:** Because it uses native scaleforms, it must be run inside a `while` loop to remain visible.

- **makeInstructionalButtons(info)**
  - Draws instructional buttons using the GTA scaleform `instructional_buttons`.
  - **Parameters:**
    - `info` (`table`): An array of tables, where each entry contains:
      - `keys` (`table`): Control key codes (e.g., `{38, 29}`).
      - `text` (`string`): The label for the button.
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            makeInstructionalButtons({
                { keys = {38, 29}, text = "Open Menu" },
                { keys = {45}, text = "Close Menu" }
            })
            Wait(0)
        end
    end)
    ```

- **makeRedInstructionalButtons(info, title)**
  - Experimental: Displays prompts using RedM-style `PromptSetGroup` API.
  - **Note:** Still must be run in a loop for visibility.
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            makeRedInstructionalButtons({
                { keys = {0x760A9C6F}, text = "Mount Horse" },
                { keys = {0x4CC0E2FE}, text = "Dismount" }
            }, "Horse Controls")
            Wait(0)
        end
    end)
    ```

### scaleform_basic.lua
This module includes helper functions for 3D text rendering and UI overlays using basic native scaleform techniques.

- **DrawText3D(coord, text, highlight)**

  - Draws 3D text in the world at the given coordinates, with optional highlight.
  - Includes a semi-transparent black background box for visibility.
  - **Parameters:**
    - `coord` (`vector3`): World position to draw text.
    - `text` (`string`): Text content.
    - `highlight` (`boolean`, optional): Highlights `~w~` sections with yellow.
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            DrawText3D(vector3(100, 200, 300), "Hello World", true)
            Wait(0)
        end
    end)
    ```

- **DisplayHelpMsg(text)**
  - Shows a help message in the top-left corner of the screen.
  - **Example:**
    ```lua
    DisplayHelpMsg("Press E to interact")
    ```

- **displaySpinner(text)**
  - Shows a busy spinner with a message (e.g., "Saving...").
  - **Example:**
    ```lua
    displaySpinner("Saving data...")
    ```

- **stopSpinner()**
  - Hides any active busy spinner (client-only).
  - **Example:**
    ```lua
    stopSpinner()
    ```

### timerBars.lua
This module provides a native scaleform-based timer bar HUD. Ideal for displaying tasks, loading indicators, or time-sensitive objectives.

- **createTimerHud(title, data, alpha)**

  ⚠️ This was an attempt to recreate the gta native shooting ranges )fairly specific use case)
  - Draws a timer bar with custom label and right-aligned values using the native GTA HUD system.
  - **Parameters:**
    - `title` (`string`): Title/header displayed on the bar.
    - `data` (`table`): List of `label = value` entries to display (max 4 rows).
    - `alpha` (`number`, optional): Opacity of the bar (0-255).
  - **Example:**
    ```lua
    CreateThread(function()
        while true do
            createTimerHud("Timer Bar", {
                { stat = "Health", value = "85%" },
                { stat = "Armor", value = "50%", multi = 2 },
                { stat = "Stamina", value = "100%" },
            }, 180)
            Wait(0)
        end
    end)
    ```
