let onboardingContainer = document.getElementById("onboarding-container");
let onboardingTextContents = document.getElementById("onboarding-text-contents");
let onboardingButton = document.getElementById("onboarding-btn");

let alreadyFoundPrices = false;
let onboardingIndex = 0;

function startOnboarding(foundPrices) {
    alreadyFoundPrices = foundPrices;
    onboardingTextContents.innerText = "Welcome to Out of C!";
    onboardingContainer.style.display = "";
    onboardingIndex = 0;
}


function onboardingNext() {
    onboardingIndex += 1;
    if (onboardingIndex == 1) {
        onboardingContainer.style.setProperty("--o", "20px");
        onboardingContainer.style.setProperty("--x", "2px");
        onboardingContainer.style.setProperty("--y", "0px");
        onboardingContainer.style.setProperty("--w", "255px");
        onboardingContainer.style.setProperty("--h", "343px");
        onboardingTextContents.innerText = "Here you can view and edit your active Voyage's info!";
    } else if (onboardingIndex == 2) {
        onboardingContainer.style.setProperty("--o", "-145px");
        onboardingContainer.style.setProperty("--x", "calc(50% - 650px / 2)");
        onboardingContainer.style.setProperty("--y", "calc(100% - 110px)");
        onboardingContainer.style.setProperty("--w", "650px");
        onboardingContainer.style.setProperty("--h", "110px");
        onboardingContainer.style.setProperty("--ox", "-115px");

        onboardingTextContents.innerText = "Here you can see the time left until the next island!";
    } else if (onboardingIndex == 3) {
        if (alreadyFoundPrices) {
            onboardingContainer.style.setProperty("--x", "50%");
            onboardingContainer.style.setProperty("--y", "50%");
            onboardingContainer.style.setProperty("--w", "0px");
            onboardingContainer.style.setProperty("--h", "0px");
            onboardingContainer.style.setProperty("--o", "-50%");
            onboardingContainer.style.setProperty("--ox", "0px");
            onboardingTextContents.innerText = "I see you've already linked an existing hackatime project and already reached your first island!\nLet's check it out!";
        } else {
            onboardingContainer.style.setProperty("--o", "0px");
            onboardingContainer.style.setProperty("--ox", "-415px");
            onboardingContainer.style.setProperty("--x", "calc(100% - 75px)");
            onboardingContainer.style.setProperty("--y", "90px");
            onboardingContainer.style.setProperty("--w", "70px");
            onboardingContainer.style.setProperty("--h", "67px");
            onboardingTextContents.innerText = "If you need help getting started, you can click here to access the docs!";
        }
    } else if (onboardingIndex == 4) {
        if (alreadyFoundPrices) {
            loadPrices(alreadyFoundPrices);
            fadeIn(islandFound);
            islandFound.style.animationPlayState = "running";
            onboardingContainer.style.display = "none";
        }
        else {
            onboardingContainer.style.setProperty("--x", "50%");
            onboardingContainer.style.setProperty("--y", "50%");
            onboardingContainer.style.setProperty("--w", "0px");
            onboardingContainer.style.setProperty("--h", "0px");
            onboardingContainer.style.setProperty("--o", "-50%");
            onboardingContainer.style.setProperty("--ox", "0px");
            onboardingTextContents.innerText = "Otherwise, feel free to ask for help in the #out-to-c channel (or just hang out!)";
        }
    } else {
        onboardingContainer.style.display = "none";
    }
}
