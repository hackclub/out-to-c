let activeVoyageScreen = document.getElementById("active-voyage");
let noExistingVoyageScreen = document.getElementById("no-existing-voyage");
let newVoyageBtn = document.getElementById("new-voyage");
let newVoyageDiv = document.getElementById("new-voyage-div");
let newVoyageBack = document.getElementById("new-voyage-back");
let newVoyageTitle = document.getElementById("new-voyage-title");
let newVoyageSubmitBtn = document.getElementById("new-voyage-form-submit");
let deleteVoyageBtn = document.getElementById("delete-voyage-button");
let logo = document.getElementById("logo");
let cargo = document.getElementById("cargo");
let treasureSelect = document.getElementById("treasure-select");
let islandFound = document.getElementById("island-found");
let newVoyageButtons = document.getElementById("new-voyage-buttons");
let priceForm = document.getElementById("price-form");
let minimapText = document.getElementById("minimap-text");
let minimap = document.getElementById("minimap");
let cargoSlots = document.getElementById("cargo-slots");
let draggingCargoSlot = document.getElementById("cargo-slot-dragging");
let cargoInfoContents = document.getElementById("cargo-info-contents");
let cargoInfoImg = document.getElementById("cargo-info-img");
let cargoInfoText = document.getElementById("cargo-info-text");
let voyageInfo = document.getElementById("voyage-info");
let voyageInfoName = document.getElementById("voyage-info-name");
let voyageInfoDesc = document.getElementById("voyage-info-desc");
let voyageInfoRepo = document.getElementById("voyage-info-repo");
let voyageInfoHackatime = document.getElementById("voyage-info-hackatime");
let notice = document.getElementById("notice");
let pricesButtons = document.getElementById("prices-buttons");
let priceSubmitBtn = document.getElementById("price-submit-btn");
let confirmationContainer = document.getElementById("confirmation-container");
let confirmationText = document.getElementById("confirmation-text");
let deleteVoyageForm = document.getElementById("delete-voyage-form");
let shipButton = document.getElementById("ship-button");
let shippedVoyageScreen = document.getElementById("shipped-voyage");
let shippedOrActiveVoyageScreen = document.getElementById("shipped-or-active-voyage");
let prizeGot = document.getElementById("prize-got");
let shipPiiBtn = document.getElementById("ship-pii-submit");
let openableMapHolder = document.getElementById("openable-map-holder");
let newVoyageAfterShipButton = document.getElementById("new-voyage-after-ship");

let elementsState = {};
for (let element of document.getElementsByTagName("*")) {
    if (element.id) {
        elementsState[element.id] = (getComputedStyle(element).display != "none");
    }
}

function showNotice(text) {
    notice.children[0].innerText = text;
    notice.style.display = "unset";
}

function hideNotice() {
    notice.style.display = "none";
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

let confirmationCallback = null;
let confirmationOpen = false;
function showConfirmation(text, callback) {
    confirmationCallback = callback;
    confirmationText.innerHTML = text;
    fadeIn(confirmationContainer);
    confirmationOpen = true;
}
function confirmConfirmation() {
    fadeOut(confirmationContainer);
    confirmationCallback();
    confirmationOpen = false;
}
function cancelConfirmation() {
    fadeOut(confirmationContainer);
    confirmationOpen = false;
}

let mapOpen = false;
function toggleMap() {
    mapOpen = !mapOpen;
    openableMapHolder.style.display = mapOpen ? "block" : "none";
}
function hideMap() {
    mapOpen = false;
    openableMapHolder.style.display = "none";
}

function tryDeleteVoyage() {
    showConfirmation("Are you sure you want to delete the active Voyage?", () => {
        deleteVoyageForm.submit();
    });
}

function tryShipVoyage() {
    if (cargoShown) { toggleCargo(); }
    showConfirmation(
        `<h2>Are you sure you want to ship this project?</h2>
        <span class="lightish">
        Only do this once your project is finished!<br>
        Your project will be reviewed, after which you will receive all prizes you have claimed so far!<br>
        Requirements for shipping:
        <ul style="margin:0">
            <li>Valid project name, description and repository</li>
            <li>README.md file which explains your project and how to use it</li>
            <li>A project made with C/C++</li>
        </ul>
        </span>`, () => { document.getElementById("ship-pii-container").style.display = "" });
}

document.forms['ship-pii-form'].addEventListener('submit', (event) => {
    event.preventDefault();
    shipPiiBtn.setAttribute("disabled", "");
    fetch(event.target.action, {
        method: 'POST',
        body: new URLSearchParams(new FormData(event.target))
    }).then((response) => {
        shipPiiBtn.removeAttribute("disabled");
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
    }).then((body) => {
        if (body["error"]) {
            showNotice("Error: " + body["error"]);
            return;
        }
        fadeOut(activeVoyageScreen);
        fadeIn(shippedVoyageScreen);
        setShipDirection(-1);
    }).catch((error) => {
        showNotice("Error: Not success :(");
        console.error(error);
    });
});

function selectTreasure() {
    treasureSelect.classList.add("treasure-select-fade");
}

document.addEventListener("keydown", (event) => {
    if (event.code == "Escape") {
        if (confirmationOpen) { cancelConfirmation(); }
        else if (inNewVoyage || editingVoyage) { backVoyage(); }
        else if (cargoShown) { toggleCargo(); }
        else if (getComputedStyle(notice).display != "none") { hideNotice(); }
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

function formDataToArray(fd) {
    let a = [];

    for (let pair of fd.entries()) {
        const key = pair[0];
        if (key == "image_data") {
            continue;
        }
        a.push({ [key]: pair[1] })
    }
    return a;
}

let voyageChangesMade = false;
let lastForm = formDataToArray(new FormData(document.forms["new-voyage-form"]));
function hasVoyageChanged() {
    if (voyageChangesMade) { return true; }
    return JSON.stringify(lastForm) !== JSON.stringify(formDataToArray(new FormData(document.forms["new-voyage-form"])));
}

globalThis.backVoyage = function () {
    if (inNewVoyageAfterShip) {
        newVoyageAfterShipButton.style.display = "";
        fadeOut(newVoyageDiv);
        fadeOut(newVoyageBack);
        return;
    }
    if (editingVoyage) {
        let goBack = () => {
            editingVoyage = false;
            fadeOut(newVoyageDiv);
            fadeOut(newVoyageBack);
            fadeIn(voyageInfo);
        };
        if (hasVoyageChanged()) {
            showConfirmation("Are you sure you want to stop editing your Voyage?<br>You have unsaved changes!", goBack);
        } else {
            goBack();
        }
        return;
    }
    inNewVoyage = false;
    setCameraState(0);
    fadeIn(newVoyageButtons);
    fadeOut(newVoyageDiv);
    fadeOut(newVoyageBack);
    fadeIn(logo);
}
let cargoShown = elementsState[cargo.id];
globalThis.toggleCargo = function () {
    if (cargoShown) {
        fadeOut(cargo);
        if (selectedCargoSlot != null) {
            cargoInfoContents.style.display = "none";
            selectedCargoSlot.classList.remove("selected-slot");
            selectedCargoSlot = null;
        }
    } else {
        if (inNewVoyageAfterShip) {
            backVoyage();
        }
        if (editingVoyage) {
            if (hasVoyageChanged()) {
                return;
            }
            backVoyage();
        }
        fadeIn(cargo);
    }
    cargoShown = !cargoShown;
}

// Source - https://stackoverflow.com/a/12369027
// Posted by ygssoni, modified by community. See post 'Timeline' for change history
// Retrieved 2026-03-12, License - CC BY-SA 4.0

globalThis.readURL = function (input) {
    voyageChangesMade = true;
    if (input.files && input.files[0]) {
        var reader = new FileReader();

        reader.onload = function (e) {
            document.getElementById("image-link-showcase").setAttribute("src", e.target.result)
        };

        reader.readAsDataURL(input.files[0]);
    }
}

// Source - https://stackoverflow.com/a/45036752 (modified)
// Posted by user, modified by community. See post 'Timeline' for change history
// Retrieved 2026-08-10, License - CC BY-SA 4.0
function resetAnimation(el) {
    el.style.animation = 'none';
    el.offsetHeight; /* trigger reflow */
    el.style.animation = null;
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
let remainingPricesToBePicked = false;
globalThis.finalizePriceSelection = function () {
    if (selectedPriceID == "") {
        return;
    }
    if (!remainingPricesToBePicked) {
        while (prizeGot.children[0]) {
            prizeGot.children[0].remove();
        }
    }
    priceSubmitBtn.setAttribute("disabled", "");

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
        priceSubmitBtn.removeAttribute("disabled");
        if (body["error"]) {
            showNotice("Error: " + body["error"]);
            return;
        }
        fadeOut(islandFound);
        fadeIn(minimap);
        minimapText.innerText = body["next_island_remaining"] + " hours";
        pcs.push(body["price"]);

        var children = cargoSlots.children;
        for (var i = 0; i < children.length; i++) {
            if (children[i].tagName != "DIV") {
                continue;
            }
            if (!children[i].children[0].src.includes(".png")) {
                children[i].children[0].src = body["img"];
                break;
            }
        }
        let img = document.createElement("img");
        img.src = body["img"];
        prizeGot.appendChild(img);
        if (body["fp"]) {
            remainingPricesToBePicked = true;
            loadPrices(body["fp"]);
            fadeIn(islandFound);
        } else {
            remainingPricesToBePicked = false;
            resetAnimation(prizeGot);
            fadeIn(prizeGot);
        }
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
    cargoInfoContents.style.display = this.children[0].src.includes(".png") ? "block" : "none";
    if (!this.children[0].src.includes(".png")) {
        selectedCargoSlot = null;
        return;
    }
    selectedCargoSlot = this;
    this.classList.add("selected-slot");
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
        let thisOld = this.children[0].src;
        if (!thisOld.includes(".png")) {
            thisOld = "";
        }
        this.children[0].src = draggingCargoSlot.src;
        selectedCargoSlot.children[0].src = thisOld;
        dragging = null;
        selectCargoSlot.bind(this)();
    }
}

for (let i = 0; i < 4 * 3; i++) {
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

function resetVoyageForm() {
    for (let name of ["input", "select"]) {
        var array = document.getElementsByTagName(name);
        for (var i = 0, lng = array.length; i < lng; i++) {
            if (array[i].name == "authenticity_token") {
                continue;
            }
            array[i].value = '';
        }
    }
}

let inNewVoyageAfterShip = false;
globalThis.newVoyageAfterShip = function () {
    resetVoyageForm();
    editVoyage();
    editingVoyage = false;
    inNewVoyageAfterShip = true;
    newVoyageAfterShipButton.style.display = "none";
    newVoyageTitle.innerText = "New Voyage";
    newVoyageSubmitBtn.innerText = "CREATE VOYAGE";
    for (let element of document.getElementsByClassName("input-show-on-voyage-create")) {
        element.style.display = "none";
    }
    for (let element of document.getElementsByClassName("input-hide-on-voyage-create")) {
        element.style.display = "unset";
    }
    deleteVoyageBtn.style.display = "none";
}

let editingVoyage = false;
globalThis.editVoyage = function () {
    if (cargoShown) {
        toggleCargo();
    }
    fadeIn(newVoyageDiv);
    fadeIn(newVoyageBack);
    fadeOut(voyageInfo);
    editingVoyage = true;
};

document.forms['new-voyage-form'].addEventListener('submit', (event) => {
    event.preventDefault();
    newVoyageSubmitBtn.setAttribute("disabled", "");
    fetch(event.target.action, {
        method: 'POST',
        body: new FormData(event.target)
    }).then((response) => {
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
    }).then((body) => {
        newVoyageSubmitBtn.removeAttribute("disabled");
        if (body["error"]) {
            showNotice("Error: " + body["error"]);
            return;
        }
        if (inNewVoyageAfterShip) {
            location.reload();
            return;
        }
        voyageChangesMade = false;
        lastForm = formDataToArray(new FormData(document.forms["new-voyage-form"]));
        inNewVoyage = false;
        voyage = parseInt(body["id"]);
        fadeOut(newVoyageDiv);
        fadeOut(newVoyageBack);
        fadeOut(noExistingVoyageScreen);
        fadeIn(activeVoyageScreen);
        fadeIn(shippedOrActiveVoyageScreen);
        if (editingVoyage) {
            fadeIn(voyageInfo);
        }
        setTravelDistance(body["total_seconds"] / 60.0 / 60.0);
        minimapText.innerText = body["next_island_remaining"] + " hours";
        voyageInfoName.innerText = body["name"];
        voyageInfoDesc.innerText = body["desc"];
        voyageInfoRepo.innerText = body["repo"];
        voyageInfoRepo.href = body["repo_url"];
        voyageInfoHackatime.innerText = body["hackatime-text"];
        deleteVoyageBtn.style.display = "block";

        if (!originalVoyageID) {
            if (!hasPastVoyages) {
                startOnboarding(body["fp"]);
            }
            originalVoyageID = 1;
        } else {
            if (body["fp"]) {
                loadPrices(body["fp"]);
                fadeIn(islandFound);
                islandFound.style.animationPlayState = "running";
            }
        }

        newVoyageTitle.innerText = "Edit Voyage";
        newVoyageSubmitBtn.innerText = "SAVE CHANGES";
        for (let element of document.getElementsByClassName("input-show-on-voyage-create")) {
            element.style.display = "unset";
        }
        for (let element of document.getElementsByClassName("input-hide-on-voyage-create")) {
            element.style.display = "none";
        }
    }).catch((error) => {
        showNotice("Error: Not success :(");
        console.error(error);
    });
});

function loadPrices(found_prices) {
    while (pricesButtons.children[0]) {
        pricesButtons.children[0].remove();
    }
    let i = 0;
    for (let [key, value] of Object.entries(found_prices)) {
        let img = document.createElement("img");
        img.src = value["src"];
        let hr = document.createElement("hr");
        let span = document.createElement("span");
        span.innerText = value["name"];
        let button = document.createElement("button");
        button.classList.add("treasure-select-btn");
        button.id = "priceButton" + i;
        button.onclick = selectPrice.bind(null, key, i);
        button.appendChild(img);
        button.appendChild(hr);
        button.appendChild(span);
        pricesButtons.appendChild(button);
        pricesButtons.appendChild(document.createTextNode(" "));
        i += 1;
    }
}
loadPrices(found_prices);