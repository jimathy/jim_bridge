let buttonParams = [];
let menuItems = [];

const openMenu = (data = null) => {
    let html = "<div id='buttons'>";

    // Add search as a title-like fixed header
    html += `
        <div class="title search-container">
            <input type="text" id="search-input" placeholder="Search..." autocomplete="off">
        </div>
    `;

    data.forEach((item, index) => {
        if (!item.hidden) {
            let header = item.header || item.title;
            let message = item.txt || item.text || item.description;
            let isMenuHeader = item.isMenuHeader;
            let isDisabled = item.disabled;
            let icon = item.icon;
            let progress = item.progress || item.progressbar;
            let colour = item.colorScheme;
            html += getButtonRender(header, message, index, isMenuHeader, isDisabled, icon, progress, colour);
            if (item.params) buttonParams[index] = item.params;
        }
    });

    html += "</div>";

    $("#container").html(html);

    $('.button').click(function() {
        const target = $(this)
        if (!target.hasClass('title') && !target.hasClass('disabled')) {
            postData(target.attr('id'));
        }
    });

    $("#search-input").on("input", function() {
        const value = $(this).val().toLowerCase();
        $("#buttons .button, #buttons .title").filter(function(index) {
            if (index === 0) return; // Skip the search bar itself (first title)
            $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1);
        });
    });
};

const getButtonRender = (header, message = null, id, isMenuHeader, isDisabled, icon, progress, colour) => {
    return `
        <div class="${isMenuHeader ? "title" : "button"} ${isDisabled ? "disabled" : ""} " id="${id}">
            ${icon ? `
                <div class="icon">
                    <img src=${icon} onerror="this.onerror=null; this.remove();">
                    <i class="${icon}" onerror="this.onerror=null; this.remove();"></i>
                </div>
            ` : " " }
            <div class="column">
                <div class="header">${header ? `${header}` : " "}</div>
                ${message ? `<div class="text"> ${message}</div>` : ""}
            </div>
        </div>

        ${progress ? `
            <div class="progress-container">
                <div class="progress-bar" style="width: ${progress}%; background-color: ${colour};"></div>
            </div>`
        : ""}
    `;
};

const closeMenu = () => {
    $("#buttons").html(" ");
    buttonParams = [];
    $("#search-input").hide(); // hide search bar
};

const postData = (id) => {
    $.post(`https://${GetParentResourceName()}/clickedButton`, JSON.stringify(parseInt(id) + 1));
    return closeMenu();
};

const cancelMenu = () => {
    $.post(`https://${GetParentResourceName()}/closeMenu`);
    return closeMenu();
};

const filterButtons = (query) => {
    const filteredItems = menuItems.filter(item => item.header.toLowerCase().includes(query.toLowerCase()));
    openMenu(filteredItems);
};

$("#search-input").on('input', function() {
    filterButtons($(this).val());
});

document.onkeyup = function (event) {
    const charCode = event.key;
    if (charCode == "Escape") {
        cancelMenu();
    }
};

let inputCallbackId = null;

window.addEventListener("message", (event) => {
    const data = event.data;
    const buttons = data.data;
    const action = data.action;
    debugLog("Opening Input Popup", data.data); // Log the input config specifically

    switch (action) {
        case "OPEN_MENU":
        case "SHOW_HEADER":
            return openMenu(buttons);
        case "CLOSE_MENU":
            return closeMenu();
        case "SHOW_INPUT":
            inputCallbackId = data.cbId;
            debugLog("Opening Input Popup", data.data); // Log the input config specifically
            return openInputPopup(data.data);
        default:
            return;
    }
});

document.onkeyup = function (event) {
    const charCode = event.key;
    if (charCode == "Escape") {
        cancelMenu();
    }
};

const openInputPopup = (config) => {
    if (!config || !Array.isArray(config)) {
        console.error("Invalid input config: missing or malformed 'fields'", config);
        return;
    }
    const container = document.getElementById("input-popup");
    const form = document.getElementById("input-form");
    form.innerHTML = ""; // clear form

    config.forEach(field => {
        let input;

        switch (field.type) {
            case "text":
            case "number":
                input = document.createElement("input");
                input.type = field.type;
                break;
            case "radio":
                input = document.createElement("input");
                input.type = "radio";
                break;
            case "select":
                input = document.createElement("select");
                field.options.forEach(opt => {
                    const option = document.createElement("option");
                    option.value = opt;
                    option.textContent = opt;
                    input.appendChild(option);
                });
                break;
            case "slider":
                input = document.createElement("input");
                input.type = "range";
                input.min = field.min;
                input.max = field.max;
                input.step = field.step || 1;
                break;
            case "color":
                input = document.createElement("input");
                input.type = "color";
                break;
        }

        if (!input) return;

        input.name = field.name;
        input.className = "input-field";
        input.placeholder = field.label || field.placeholder || "";
        if (field.required) input.required = true;

        const wrapper = document.createElement("div");
        wrapper.className = "input-wrapper";
        if (field.type === "radio") {
            if (field.label) {
                const titleLabel = document.createElement("label");
                titleLabel.className = "input-label";
                titleLabel.textContent = field.label;
                wrapper.appendChild(titleLabel);
            }

            if (Array.isArray(field.options)) {
                field.options.forEach(opt => {
                    const radioWrapper = document.createElement("label");
                    radioWrapper.className = "radio-wrapper";

                    const radio = document.createElement("input");
                    radio.type = "radio";
                    radio.name = field.name;
                    radio.value = opt.value;
                    radio.className = "radio-input";

                    // Set default checked radio
                    if (field.default === opt.value) {
                        radio.checked = true;
                    }

                    const label = document.createElement("span");
                    label.className = "radio-label";
                    label.textContent = opt.label || opt.value;

                    radioWrapper.appendChild(radio);
                    radioWrapper.appendChild(label);
                    wrapper.appendChild(radioWrapper);
                });
            }

            form.appendChild(wrapper);
            return;
        }

        if (field.type === "color") {
            if (field.label) {
                const titleLabel = document.createElement("label");
                titleLabel.className = "input-label";
                titleLabel.textContent = field.label;
                wrapper.appendChild(titleLabel);
            }
            const colorPreview = document.createElement("span");
            colorPreview.className = "color-preview";
            colorPreview.textContent = input.value;

            input.addEventListener("input", () => {
                const hex = input.value;
                const rgb = hexToRgb(hex);
                colorPreview.textContent = `${hex.toUpperCase()} (${rgb})`;
            });
            wrapper.classList.add("color-picker");

            wrapper.appendChild(input);
            wrapper.appendChild(colorPreview);
            form.appendChild(wrapper);
            return;
        }

        if (field.type === "slider") {
            if (field.label) {
                const titleLabel = document.createElement("label");
                titleLabel.className = "input-label";
                titleLabel.textContent = field.label;
                wrapper.appendChild(titleLabel);
            }
            input.value = field.default || field.min;
            const sliderValue = document.createElement("div");
            sliderValue.className = "slider-values";
            sliderValue.innerHTML = `
                <span class="slider-min">${field.min}</span>
                <span class="slider-current">${input.value}</span>
                <span class="slider-max">${field.max}</span>
            `;

            input.addEventListener("input", () => {
                sliderValue.querySelector(".slider-current").textContent = input.value;
            });

            wrapper.appendChild(sliderValue);
            wrapper.appendChild(input);
            form.appendChild(wrapper);
            return;
        }

        // Common label
        const label = document.createElement("label");
        label.className = "input-label";
        label.textContent = field.label || field.name || "Input";
        wrapper.appendChild(label);

        // Input
        input.name = field.name;
        input.className = "input-field";
        if (field.required) input.required = true;
        wrapper.appendChild(input);

        form.appendChild(wrapper);

        form.appendChild(wrapper);
    });

    form.onsubmit = function (e) {
        e.preventDefault();
        const data = {};
        new FormData(form).forEach((val, key) => {
            // checkboxes return "on" when checked
            if (form[key].type === "checkbox") {
                data[key] = form[key].checked;
            } else if (form[key].type === "color") {
                const hex = val;
                const rgb = hexToRgb(hex);
                data[key] = {
                    hex: hex.toUpperCase(),
                    rgb: rgb
                };
            } else {
                data[key] = val;
            }
        });
        returnInputData(data);
    };

    document.querySelector(".input-cancel").onclick = () => {
        returnInputData(null);
    };

    container.classList.remove("hidden");
};

const closeInputPopup = () => {
    document.getElementById("input-popup").classList.add("hidden");
};

const returnInputData = (result) => {
    $.post(`https://${GetParentResourceName()}/inputResult`, JSON.stringify({
        cbId: inputCallbackId,
        result
    }));
    closeInputPopup();
};

const debugLog = (label, data) => {
    //console.log(`^4[DEBUG] ${label}`);
    //console.log(JSON.stringify(data, null, 2));
};

function hexToRgb(hex) {
    const bigint = parseInt(hex.slice(1), 16);
    const r = (bigint >> 16) & 255;
    const g = (bigint >> 8) & 255;
    const b = bigint & 255;
    return `RGB(${r}, ${g}, ${b})`;
}