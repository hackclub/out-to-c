let form = document.getElementById('submit');

function reviewerSubmit(approved) {
    let body = new FormData(form);
    body.append("approved", approved);
    fetch(form.action, {
        method: 'POST',
        body: new URLSearchParams(body)
    }).then((response) => {
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
    }).then((body) => {
        if (body["error"]) {
            alert("Error: " + body["error"]);
            return;
        }
        document.location.href = "/reviewer";
    }).catch((error) => {
        alert("Error: Not success :(");
        console.error(error);
    });
}
form.addEventListener('submit', (event) => { event.preventDefault() });