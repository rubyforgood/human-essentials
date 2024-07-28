DRAFT USER GUIDE 

# Organization information and customization

Every essentials bank has its own way of doing things. 
With that in mind, there are a number of things you can tweak. 
This is done through "My Organization". 
Only organization admins have access to this area.

## Getting to the organization edit

Scroll down to the bottom of the left-hand menu (you may have to collapse areas that you've opened)to the last item.  Click on "My Organization".

This brings up a view of the organization settings. It shows everything we are going to talk about for the rest of this section, as well as the users (more on them in the next section)
Scroll down until you see an Edit button.  Click it.

You should now be in a screen that is titled "Editing [Your bank name]"

Here's all the fields, with a bit about the implications of each one:

## Basic Information 
### Name
The name of your essentials bank.   This appears in the headings on most screens, and will appear on printouts (such as the distribution printout many banks use as a packing slip), and most reports.

### Short name
You don't change this -- we assigned it when we set it up -- it's here for reference for support calls if we need it.

### NDBN membership
This should be filled in already from your account request,but if it isn't, you can select it from the list.   That list is updated on an irregular basis,  so if you are an NDBN member, and you aren't on the list,  let us know and we'll get a fresh list uploaded.
This is included on the Annual survey report.  That's the only effect.

### Url
Your essentials bank's website address.  This is mostly used during the account request process, so we can check if you are a good fit before you invest a lot of time and energy into the system.

### Email
Your essential bank's email address.  This is shown to the partners on their help page, and is included in reminder emails, so please use an email that is monitored.   This email is also included on distribution and donation printouts and the annual survey [TODO:  Confirm each of those.]

### Address
Your essential bank's primary address.   This is shown on the distribution and donation printouts, and the annual survey [TODO:  Confirm annual survey]

## Reminder Emails (optional)
You can opt, on a partner by partner basis, to have reminder emails sent.  
There is also a check-box on the partner that must be checked for the partner to get these emails.


The text of this email will be:  

Hello [Partner's name],

This is a friendly reminder that [Your bank's name] requires your human essentials requests to be submitted by [the deadline date, including month and year]
if you would like to receive a distribution next month.

Please log into Human Essentials at https://humanessentials.app before this date and submit your request if you are intending to submit an essentials request.

Please contact [Your bank's name] at <%= @organization.email %>
if you have any questions about this!






### Reminder day (Day of month an e-mail reminder is sent to partners to submit requests)
 At this point, we send those emails once a month on the day of the month you indicate here.
If you do not pick a day, no reminder emails are sent.

### Deadline day (Final day of the month to submit requests)
This day will be included in the reminder email message, 


## Default Intake Location

This is the  default storage location for donations and purchases.  
If you specify this, it will be pre-populated as the storage location when you are adding new donations or purchases.

## Partner Profile Sections
The [Partner Profile](pm_partner_profiles.md) is a very large form that includes a lot of information.   You might not care about all of it.
This field lets you specify which of the sub-sections of that form will be used.  
The Agency Information subsection is always included.
If you do not specify any sections,  they will all be included.  
The sections are:  
- Media Information
- Agency Stability
- Organizational Capacity
- Sources of Funding
- Area Served
- Population Served
- Agency Distribution Information
- Attached Documents

## Default Storage Location

The bank-wide default storage location for donations and purchases.  
You can also specify a different default storage location on any partner, which will override this default.
If you specify a default storage location, it will be pre-populated as the storage location when you are adding new distributions.

## Custom Partner Invitation Message
[TODO:  Ensure that this is working!] 

When you invite a partner, they get an email.  This field lets you specify the message you are sending to them.  Just text -- we don't have any personalization capability for this email at this time.

If you do not specify a message, the invitation will contain:  

Hello [partner's email]

You've been invited to become a partner with Pawnee Diaper Bank!

Please click the link below to accept your invitation and create an account and you'll be able to begin requesting distributions.

Please contact [bank's email] if you are encountering any issues.

Accept Invitation
For security reasons these invitations expire. This invitation will expire in 8 hours or if a new password reset is triggered.

If your invitation has an expired message, go here(link to the log in page) and enter your email address to reset your password.

Feel free to ignore this email if you are not interested or if you feel it was sent by mistake.


## Questions for the annual survey
These fields are only here to be reported on the annual survey.

### Does your bank repackage essentials?
### Does your bank distribute monthly

## Custom Units
The number of items throughout the bank's view of the system is the number of units (e.g. diapers), but 
partners often think in terms of packs of diapers.   Because banks were getting a lot of partners requesting the number of packs of diapers, instead of the number of diapers, we have introduced the ability for banks to allow the partners to request other units (e.g. packs)

This deserves a page of it's own - but in short,  you can specify units here, that you can add to your items.   The partners then can ask for, say, 'packs' of diapers.   You will still have to translate those to the number of items when distributing
Because there is a lot of variety in pack size across brands.

[TODO:  This is actually a good candidate for a video showing the whole process]

## Controlling what kind of request a partner can make

There are three different ways a partner can request essentials -- a "Child based" request, a request by number of individuals, and a straight quantity-based request.  Some banks want to limit which requests the partners can make, in order to minimize partner confusion.
These three fields allow you to control which requests the partners can use.
If you allow more than one kind, the partner can also limit their own.
Note that if any partner limits themselves to a single type,  you won't be able to remove that type.  So, if you think you only want to allow quantity-based requests, doing that up front is a fine idea. 

### Enable partners to make child-based requests
### Enable partners to make requests for individuals?
### Enable partners to make quantity-based requests?

## Customizing the distribution printout
There are four fields that allow you to tweak the appearance of the distribution printout


### Show Year-to-date values on the distribution printout? 
Some banks don't want to show year-to-date values on the receipt (1, below) because their fiscal year is not the calendar year.  
### Include Signature Lines on Distribution Printout
If "yes", this will include a space for someone from the bank and from the partner to sign the distribution printout (2, below) - which can be useful as a receipt acknowledgement.
### Hide both value columns 
The default is to show the in-kind value of the items on the receipt (3, below).  Many banks don't need to show this information on the distribution printout.
Note:  Hiding this also hides the corresponding values on the single donation printout. 
### Hide the package column on distribution receipts?
This hides the packages column on the distribution printout (4, below).  Because different brands of essentials use different size packages,  this
column is useful mainly for banks that repackage their essentials into uniform package sizes.  If you have a uniform package size, you can specify that on the item (see [Inventory Items](inventory_items.md))

![distribution printout marked up with customizable sections](images/getting_started/customization/gs_customization_distribution_printout_customizable_sections.png)

## Use One Step Invite and Approve partner process?
Partners can't submit requests until they are approved by the bank.
The full partner approval process requires the partner to fill in their profile and submit it for approval.  Some banks handle that for their partners,  gather the information through other means (such as a phone conversation). 
Checking this will change the process so that the partners are automatically approved when they are invited. Note that any invited partners that are not yet approved will still need to be approved by the bank.

## Distribution Email Content
Note that there is a checkbox on the partner for them to receive distribution emails.  We recommend you do customize this content, as the default text is abrupt.
You can customize this quite a bit!  [TODO:  expand.   Maybe provide a real life example.]

## Logo

The logo that you upload here will appear several places throughout the system, including on your distribution and donation printouts.  Larger logos will impact your performace -- the 763 x 188 size is a good guideline.
