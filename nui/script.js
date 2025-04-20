let buttonParams = [];
let menuItems = [];

const openMenu = (data = null) => {
    let html = `
        <div class="search-container">
            <input type="text" id="search-input" placeholder="Search...">
        </div>
    `;

    html += "<div id='buttons'>";

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
    $("#buttons").html(html);
    $("#container").html(html);
    $('.button').click(function() {
        const target = $(this)
        if (!target.hasClass('title') && !target.hasClass('disabled')) {
            postData(target.attr('id'));
        }
    });

    $("#search-input").on("keyup", function() {
        let value = $(this).val().toLowerCase();
        $("#buttons .button, #buttons .title").filter(function() {
            $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
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
                ${progress ? `
                    <div style="width: 7vw; background-color: #ddd; border-radius: 5px;">
                        <div style="padding-top: 0.3vh; padding-bottom: 0.3vh; width:${progress}%; background-color:${colour}; border-radius: 5px;"></div>
                    </div>`
                : ""}
            </div>
        </div>
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

window.addEventListener("message", (event) => {
    const data = event.data;
    const buttons = data.data;
    const action = data.action;
    switch (action) {
        case "OPEN_MENU":
        case "SHOW_HEADER":
            return openMenu(buttons);
        case "CLOSE_MENU":
            return closeMenu();
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
