function calculate_client_share_total(){
    total = 0;
    const client_shares = document.querySelectorAll('*[id$="client_share"]')
    client_shares.forEach(
        cs => {total += parseInt(cs.value)});
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