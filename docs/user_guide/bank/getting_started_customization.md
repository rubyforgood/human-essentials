READY FOR REVIEW

# Organization information and customization

Every Essentials Bank has its own way of doing things. 
With that in mind, there are a number of things you can tweak. 
This is done through "My Organization". 
Only organization admins have access to this area.

## Getting to the organization edit

Scroll down to the bottom of the left-hand menu (you may have to collapse areas that you've opened) to the last option.  Click on "My Organization".

![Navigation 1](images/getting_started/customization/gs_customization_navigation_1.png)

This brings up a view of the organization settings. It shows everything we are going to talk about for the rest of this section, as well as the users (more on them in the next section)

Scroll down until you see an Edit button.  Click it.


![Navigation 1](images/getting_started/customization/gs_customization_navigation_1.png)


You should now be in a screen that is titled "Editing [Your bank name]".  Change the information to suit your organization's needs and then click the "save" button at the bottom

![Top of edit screen](images/getting_started/customization/gs_customization_top_of_edit.png)
Here's all the fields, with a bit about the implications of each one:

## Basic Information
#### Name
The name of your Essentials Bank.   This appears in the headings on most screens, and will appear on printouts (such as the distribution printout many banks use as a packing slip), and most reports.

#### Short name
You don't change this -- we assigned it when we set it up -- it's here for reference for support calls if we need it.

#### NDBN membership
This should be filled in already from your Account Request,but if it isn't, you can select it from the list.   That list is updated on an irregular basis,  so if you are an NDBN member, and you aren't on the list,  let us know and we'll get a fresh list uploaded.
This is included on the Annual Survey report.  That's the only effect.

#### Url
Your Essentials Bank's website address.  This is mostly used during the Account Request process, so we can check if you are a good fit before you invest a lot of time and energy into the system.

#### Email
Your Essential Bank's email address.  This is shown to the partners on their help page, and is included in reminder emails, so please use an email that is monitored.   This email is also included on Distribution and Donation printouts.

#### Address
Your Essential Bank's primary address.   This is shown on the distribution and Donation printouts.

------------
## Reminder Emails (optional)
You can opt, on a partner by partner basis, to have reminder emails sent.  
There is also a check-box on the Partner that must be checked for the Partner to get these emails.


The text of this email will be:  

Hello [Partner's name],

This is a friendly reminder that [Your bank's name] requires your human essentials requests to be submitted by [the deadline date, including month and year]
if you would like to receive a Distribution next month.

Please log into Human Essentials at https://humanessentials.app before this date and submit your request if you are intending to submit an essentials request.

Please contact [Your bank's name] at <%= @organization.email %>
if you have any questions about this!






#### Reminder day (Day of month an e-mail reminder is sent to partners to submit Requests)
At this point, we send those emails once a month on the day of the month you indicate here.
If you do not pick a day, no reminder emails are sent.

#### Deadline day (Final day of the month to submit Requests)
This day will be included in the reminder email message, 

----------

#### Default Intake Location

This is the  default storage location for Donations and Purchases.  
If you specify this, it will be pre-populated as the storage location when you are adding new Donations or Purchases.

#### Partner Profile Sections
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

#### Default Storage Location

The bank-wide default Storage Location for Donations and Purchases.  
You can also specify a different default Storage Location on any Partner, which will override this default.
If you specify a default Storage Location, it will be pre-populated as the Storage Location when you are adding new Distributions.

#### Custom Partner Invitation Message 
[!NOTE] The Custom Partner Invitation Message is currently not working as advertised (as of November 13, 2024.).  The current behavior is as if you did not enter anything here.  We have fixing it on our "to do" list.

When you invite a Partner, they get an email.  This field lets you specify the message you are sending to them.  Just text -- we don't have any personalization capability for this email at this time.

If you do not specify a message, the invitation will contain:  

Hello [Partner's email]

You've been invited to become a partner with Pawnee Diaper Bank!

[Customer Partner Invitation Message If Present]

Please click the link below to accept your invitation and create an account and you'll be able to begin requesting Distributions.

Please contact [Bank's email] if you are encountering any issues.

[Accept Invitation button]

For security reasons these invitations expire. This invitation will expire in 8 hours or if a new password reset is triggered.

If your invitation has an expired message, go here(link to the log in page) and enter your email address to reset your password.

Feel free to ignore this email if you are not interested or if you feel it was sent by mistake.

----------
## Questions for the Annual Survey
These two fields are only here to be reported on the Annual Survey.

#### Does your Bank repackage essentials?
#### Does your Bank distribute monthly

-----------

#### Custom Units

NOTE:  This is not yet implemented as of Oct 12, 2024. We expect it to be implemented before this guide is launched.

This is a special topic that has its own guide page [here](special_custom_units.md).  

----------

## Controlling what kind of Requests a Partner can make

There are three different ways a Partner can request essentials -- a "Child based" Request, a Request by number of individuals, and a quantity-based Request.  Some banks want to limit which Requests the partners can make, in order to minimize partner confusion.
These three fields allow you to control which Requests the Partners can use.
If you allow more than one kind, the Partner can also limit their own.
Note that if any Partner limits themselves to a single type,  you won't be able to remove that type.  So, if you think you only want to allow quantity-based Requests, doing that up front is a fine idea. 

#### Enable partners to make child-based Requests
#### Enable partners to make Requests for individuals?
#### Enable partners to make quantity-based Requests?

----------

## Customizing the Distribution printout
There are four fields that allow you to tweak the appearance of the Distribution printout 

### Show Year-to-date values on the Distribution printout? 
Some banks don't want to show year-to-date values on the receipt (1, below) because their fiscal year is not the calendar year.  
### Include Signature Lines on Distribution printout
If "yes", this will include a space for someone from the bank and from the Partner to sign the Distribution printout (2, below) - which can be useful as a receipt acknowledgement.
### Hide both value columns 
The default is to show the in-kind value of the Items on the receipt (3, below).  Many banks don't need to show this information on the Distribution printout.
Note:  Hiding this also hides the corresponding values on the single Donation printout. 
### Hide the package column on Distribution receipts?
This hides the packages column on the Distribution printout (4, below).  Because different brands of essentials use different size packages,  this
column is useful mainly for banks that repackage their essentials into uniform package sizes.  If you have a uniform package size, you can specify that on the Item (see [Inventory Items](inventory_items.md))

![Distribution printout marked up with customizable sections](images/getting_started/customization/gs_customization_distribution_printout_customizable_sections.png)

--------

#### Use One Step Invite and Approve partner process?
Partners can't submit Requests until they are approved by the bank.
The full partner approval process requires the partner to fill in their profile and submit it for approval.  Some banks handle that for their partners,  gather the information through other means (such as a phone conversation). 
Checking this will change the process so that the partners are automatically approved when they are invited. Note that any invited partners that are not yet approved will still need to be approved by the bank.

#### Distribution Email Content
Note that there is a checkbox on the partner for them to receive Distribution emails.  We recommend you do customize this content, as the default text is abrupt.
You can customize this quite a bit! 

Specifically, you can use the variables %{partner_name}, %{delivery_method}, %{distribution_date}, and %{comment} to include the partner's name, delivery method, distribution date, and comments sent in the email.  You can also format the text, and attach files by using the buttons above the field.

Here's a real-life example (except for the URL)

------

%{partner_name},

Your essentials request has been approved and you can find attached to this email a copy of the distribution you will be receiving.

Your distribution has been set to be %{delivery_method} on %{distribution_date}.

Friendly reminder: don't forget to keep up with important updates at https://example.com. Subscribe there to get email notifications when updates are posted!

See you soon!

%{comment}

-----





#### Logo

The logo that you upload here will appear several places throughout the system, including on your Distribution and Donation printouts.  Larger logos will impact your performance -- the 763 x 188 size is a good guideline.

[Prior: Inventory](getting_started_inventory.md) [Next:  Adding your Staff - levels of access](getting_started_access_levels.md)