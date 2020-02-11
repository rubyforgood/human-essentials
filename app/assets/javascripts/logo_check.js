$(document).ready(function () {
    $(document).on('change', '#organization_logo', check_file);

    function check_file() {
        if (!window.FileReader) {
            //alert("The file API isn't supported on this browser yet.");
            return;
        }

        input = document.getElementById('organization_logo');
        if (input.files[0]) {
            file = input.files[0];
            if (!file.type.match(/^image\/(jpg|jpeg|pjpeg|png|x-png)$/)) {
                input.value = null;
                alert("file type is not allowed (only jpeg/png images)");
            }
        }
    }
});