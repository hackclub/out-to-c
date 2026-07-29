let activeVoyageScreen = document.getElementById("active-voyage");
let noExistingVoyageScreen = document.getElementById("no-existing-voyage");
let newVoyageBtn = document.getElementById("new-voyage");
let newVoyageDiv = document.getElementById("new-voyage-div");
let newVoyageBack = document.getElementById("new-voyage-back");
let logo = document.getElementById("logo");
let cargo = document.getElementById("cargo");

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

globalThis.newVoyage = function () {
    setCameraState(1);
    fadeOut(newVoyageBtn);
    fadeIn(newVoyageDiv);
    fadeIn(newVoyageBack);
    fadeOut(logo);
}
globalThis.backVoyage = function () {
    setCameraState(0);
    fadeIn(newVoyageBtn);
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
    }).catch((error) => {
        showNotice("Error: Not success :(");
        console.error(error);
    });
});