// Source - https://stackoverflow.com/a/12369027
// Posted by ygssoni, modified by community. See post 'Timeline' for change history
// Retrieved 2026-03-12, License - CC BY-SA 4.0
function readURL(input) {
    if (input.files && input.files[0]) {
        var reader = new FileReader();

        reader.onload = function (e) {
            document.getElementById("image-link-showcase").setAttribute("src", e.target.result)
        };

        reader.readAsDataURL(input.files[0]);
    }
}