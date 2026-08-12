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
        onboardingContainer.style.setProperty("--o", "-240px");
        onboardingContainer.style.setProperty("--x", "calc(50% - 650px / 2)");
        onboardingContainer.style.setProperty("--y", "calc(100% - 110px)");
        onboardingContainer.style.setProperty("--w", "650px");
        onboardingContainer.style.setProperty("--h", "110px");

        onboardingTextContents.innerText = "Here you can see the time left until the next island!";
    } else if (onboardingIndex == 3) {
        onboardingContainer.style.setProperty("--x", "50%");
        onboardingContainer.style.setProperty("--y", "50%");
        onboardingContainer.style.setProperty("--w", "0px");
        onboardingContainer.style.setProperty("--h", "0px");
        onboardingContainer.style.setProperty("--o", "-50%");
        if (alreadyFoundPrices) {
            onboardingTextContents.innerText = "I see you've already linked an existing hackatime project and already reached your first island!\nLet's check it out!";
        } else {
            onboardingTextContents.innerText = "If you need any help getting started, feel free to ask in the #out-to-c channel on slack!";
        }
    } else if (onboardingIndex == 4) {
        if (alreadyFoundPrices) {
            loadPrices(alreadyFoundPrices);
            fadeIn(islandFound);
            islandFound.style.animationPlayState = "running";
        }
        onboardingContainer.style.display = "none";
    }
}
