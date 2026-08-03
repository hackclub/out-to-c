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
let draggingCargoSlot = document.getElementById("cargo-slot-dragging");
let cargoInfoContents = document.getElementById("cargo-info-contents");
let cargoInfoImg = document.getElementById("cargo-info-img");
let cargoInfoText = document.getElementById("cargo-info-text");
let voyageInfoName = document.getElementById("voyage-info-name");
let voyageInfoDesc = document.getElementById("voyage-info-desc");
let voyageInfoHackatime = document.getElementById("voyage-info-hackatime");

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
let selectedCargoSlot = null;
let dragging = null;
function selectCargoSlot() {
    if (selectedCargoSlot != null) {
        if (selectedCargoSlot == this && this.children[0].src.includes(".png")) {
            dragging = this;
            draggingCargoSlot.src = this.children[0].src;
            draggingCargoSlot.style.left = clientX + "px";
            draggingCargoSlot.style.top = clientY + "px";
            return;
        }
        selectedCargoSlot.classList.remove("selected-slot");
    }
    if (!this.children[0].src.includes(".png")) {
        selectedCargoSlot = null;
        return;
    }
    selectedCargoSlot = this;
    this.classList.add("selected-slot");
    cargoInfoContents.style.display = this.children[0].src.includes(".png") ? "block" : "none";
    cargoInfoImg.src = this.children[0].src;
    pcs.forEach(element => {
        if (this.children[0].src.includes("/assets/prices/" + element[0] + "-")) {
            cargoInfoText.innerText = element[1];
        }
    });
}
function releaseCargoSlot() {
    if (dragging != null) {
        if (selectedCargoSlot == this) {
            dragging = null;
            return;
        }
        this.children[0].src = draggingCargoSlot.src;
        selectedCargoSlot.children[0].src = "";
        dragging = null;
        selectCargoSlot.bind(this)();
    }
}

for (let i = 0; i < 6 * 4; i++) {
    let element = document.getElementById("cargoSlot" + i);
    element.addEventListener("mousedown", selectCargoSlot.bind(element));
    element.addEventListener("mouseup", releaseCargoSlot.bind(element));
}
let clientX = 0;
let clientY = 0;
document.body.addEventListener("mousemove", (event) => {
    clientX = event.clientX;
    clientY = event.clientY;
    if (dragging != null) {
        draggingCargoSlot.style.left = clientX + "px";
        draggingCargoSlot.style.top = clientY + "px";
    }
});
document.body.addEventListener("mouseup", (_event) => {
    dragging = null;
    draggingCargoSlot.src = "";
});

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
        setTravelDistance(body["total_seconds"] / 60.0 / 60.0);
        minimapText.innerText = body["next_island_remaining"] + " hours";
        voyageInfoName.innerText = body["name"];
        voyageInfoDesc.innerText = body["desc"];
        voyageInfoHackatime.innerText = body["hackatime-text"];
    }).catch((error) => {
        showNotice("Error: Not success :(");
        console.error(error);
    });
});
