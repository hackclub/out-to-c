let activeVoyageScreen = document.getElementById("active-voyage");
let noExistingVoyageScreen = document.getElementById("no-existing-voyage");
let newVoyageBtn = document.getElementById("new-voyage");
let newVoyageDiv = document.getElementById("new-voyage-div");
let newVoyageBack = document.getElementById("new-voyage-back");
let logo = document.getElementById("logo");
let cargo = document.getElementById("cargo");
let treasureSelect = document.getElementById("treasure-select");
let islandFound = document.getElementById("island-found");
let newVoyageButtons = document.getElementById("new-voyage-buttons");
let priceForm = document.getElementById("price-form");
let minimapText = document.getElementById("minimap-text");
let minimap = document.getElementById("minimap");

let elementsState = {};
for (let element of document.getElementsByTagName("*")) {
    if (element.id) {
        elementsState[element.id] = (getComputedStyle(element).display != "none");
    }
}

let notice = document.getElementById("notice");

function showNotice(text) {
    notice.children[0].innerText = text;
    notice.style.display = "unset";
}

function fadeIn(element) {
    let state = elementsState[element.id];
    if (state) {
        element.classList.remove("fade-out");
    } else {
        element.classList.add("fade-in");
    }
}
function fadeOut(element) {
    let state = elementsState[element.id];
    if (state) {
        element.classList.add("fade-out");
    } else {
        element.classList.remove("fade-in");
    }
}

function selectTreasure() {
    treasureSelect.classList.add("treasure-select-fade");
}

document.addEventListener("keydown", (event) => {
    if (event.code == "Escape") {
        if (inNewVoyage) { backVoyage(); }
        if (cargoShown) { toggleCargo(); }
    }
});

let inNewVoyage = false;
globalThis.newVoyage = function () {
    inNewVoyage = true;
    setCameraState(1);
    fadeOut(newVoyageButtons);
    fadeIn(newVoyageDiv);
    fadeIn(newVoyageBack);
    fadeOut(logo);
}
globalThis.backVoyage = function () {
    inNewVoyage = false;
    setCameraState(0);
    fadeIn(newVoyageButtons);
    fadeOut(newVoyageDiv);
    fadeOut(newVoyageBack);
    fadeIn(logo);
}
let cargoShown = elementsState[cargo.id];
globalThis.toggleCargo = function () {
    console.log("wa");
    if (cargoShown) {
        fadeOut(cargo);
    } else {
        fadeIn(cargo);
    }
    cargoShown = !cargoShown;
}
let selectedPrice = -1;
let selectedPriceID = "";
globalThis.selectPrice = function (id, index) {
    if (selectedPrice != -1) {
        document.getElementById("priceButton" + selectedPrice).classList.remove("selected-price");
    }
    selectedPriceID = id;
    selectedPrice = index;
    document.getElementById("priceButton" + index).classList.add("selected-price");
}
globalThis.finalizePriceSelection = function () {
    if (selectedPriceID == "") {
        return;
    }

    data = {
        "selection": selectedPriceID,
        "authenticity_token": priceForm.children[0].value,
    }
    fetch('voyage/price', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=utf-8'
        },
        body: JSON.stringify(data)
    }).then((response) => {
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
    }).then((body) => {
        if (body["error"]) {
            showNotice("Error: " + body["error"]);
            return;
        }
        fadeOut(islandFound);
        fadeIn(minimap);
        minimapText.innerText = body["next_island_remaining"] + " hours";
    }).catch((error) => {
        showNotice("Error: Not success :(");
        console.error(error);
    });
}

document.forms['new-voyage-form'].addEventListener('submit', (event) => {
    event.preventDefault();
    fetch(event.target.action, {
        method: 'POST',
        body: new URLSearchParams(new FormData(event.target))
    }).then((response) => {
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
    }).then((body) => {
        if (body["error"]) {
            showNotice("Error: " + body["error"]);
            return;
        }
        voyage = parseInt(body["id"]);
        fadeOut(noExistingVoyageScreen);
        fadeIn(activeVoyageScreen);
        console.log(body);
        console.log(body["total_seconds"]);
        console.log(body["total_seconds"] / 60.0 / 60.0);
        setTravelDistance(body["total_seconds"] / 60.0 / 60.0);
        minimapText.innerText = body["next_island_remaining"] + " hours";
    }).catch((error) => {
        showNotice("Error: Not success :(");
        console.error(error);
    });
});
