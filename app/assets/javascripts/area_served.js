


function calculate_client_share_total(){
    total = 0;
    console.log("*********mark 1 total is: " +total);
    const client_shares = document.querySelectorAll('*[id$="client_share"]')
    client_shares.forEach(
        cs => {
            if(!cs.value || cs.offsetWidth === 0){
                return;
            }
            if(cs.value){
                total += parseInt(cs.value)
            }
        }
    );
    console.log("*********total is: " +total);
    document.getElementById("partners-served-areas-client-share-total").innerHTML = total + " %";



    if(total == 0 || total == 100){
        document.getElementById("partners-served-areas-client-share-total-warning").style.visibility= 'hidden';
        //      document.getElementById("profile-update-button").style.visibility = 'visible';
        //    document.getElementById("profile-update-button-disabled").style.visibility = 'hidden';
        //  document.getElementById("partner-county-client-share-total-warning-footer").style.visibility= 'hidden';
    }else {
        document.getElementById("partners-served-areas-client-share-total-warning").style.visibility= 'visible';
        document.getElementById("partners-served-areas-client-share-total-warning").style.color= 'red';

//        document.getElementById("profile-update-button").style.visibility = 'hidden';
        //      document.getElementById("profile-update-button-disabled").style.visibility = 'visible';
        //    document.getElementById("partner-county-client-share-total-warning-footer").style.visibility= 'visible';
        //  document.getElementById("partner-county-client-share-total-warning-footer").style.color= 'red';
    }
    return total;
}

//Following the pattern from adjustments.js

$(document).on("cocoon:after-remove", function(){
    calculate_client_share_total();
});

