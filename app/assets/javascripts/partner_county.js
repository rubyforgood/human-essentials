


function calculate_client_share_total(){
    total = 0;
    const client_shares = document.querySelectorAll('*[id$="client_share"]')
    client_shares.forEach(
        cs => {
                if(!cs.value || cs.offsetWidth === 0){
                    console.log("skipping");
                    return;
                }
                if(cs.value){
                    total += parseInt(cs.value)
                }
        }
    );
    document.getElementById("partner_county_client_share_total").innerHTML =total;

    if(total == 0 || total == 100){
        document.getElementById("partner-county-client-share-total-warning").style.visibility= 'hidden';
        document.getElementById("profile-update-button").style.visibility = 'visible';
        document.getElementById("profile-update-button-disabled").style.visibility = 'hidden';
    }else {
        document.getElementById("partner-county-client-share-total-warning").style.visibility= 'visible';
        document.getElementById("profile-update-button").style.visibility = 'hidden';
        document.getElementById("profile-update-button-disabled").style.visibility = 'visible';
    }
    return total;
}

///TODO  I'm trying to get calculate_client_share_total to fire when we remove a partner/county.   This is not working
//   Reference:  https://github.com/nathanvda/cocoon


//Following the pattern from adjustments.js

$(document).on("cocoon:after-remove", function(){
    console.print("in cocoon-after-remove callback");
    calculate_client_share_total();
});

/*
Other things I've tried  // here as a reminder that I've tried them...

$(document).ready(function(){
    $('f')
        .on('cocoon:after-remove', function() {
            console.print("in cocoon-after-remove callback");
            calculate_client_share_total();
        })});
*/
/*



            $(function() {
    $(document)
        .on('cocoon:after-remove', function(){
            console.print("in cocoon-after-remove callback");
            calculate_client_share_total();
        })
});*/