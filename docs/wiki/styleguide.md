This document is to establish some consistent norms that will be used throughout the application. Using consistent language and decoration reduces cognitive load for the users and accelerates on-boarding.

<aside class="notice">
Where possible, we have created helper methods (see: `/app/helpers/ui_helper.rb`) to simplify this and future-proof any style changes we may make. Please use these unless absolutely necessary; if none of these fit the need you have, please create a similar helper in that file and use that.
</aside>

# Forms
Ensure that all form elements have an appropriately associated label. Using the rails form helper (as in the existing forms) should produce this correctly.

## UI Components
Directive UI components (buttons, action links, some form controls) should be easily identifiable based on:

 * Text
 * Color
 * Icon
 * 508-compliant HTML Attributes (where possible)

In the case of destructive or "irreversible" changes made through a form control, an interceding confirm dialog should be used. This is primarily `:destroy` actions, but also any case where reversing the action is difficult or impossible, such as merging two records.

### Text
The text of the component should be clearly labeled with a present-tense verb that succinctly indicates what interacting will accomplish. Use simple language, and ensure words are spelled correctly. The first letter of the text should be capitalized in most cases. Use no punctuation.

If the action is too complicated to be condensed to a single word or two, and the action must all be performed at once, include a short bit of text nearby that explains what those controls will do.

### Color
Keep color scheme usage consistent across the app, for clarity. Color is for ease and quick recognition but we must be sure to use other indicators as well.

### Icons
Use whenever possible and appropriate. Like color, the icon used should be consistent with the rest of the site. The icon should be a clear "flavor fit" for what the action is. A "Create" button should use the `plus` icon. An "Edit" link, should use the `pencil` icon.

This app uses the **FontAwesome** library for icons, and we have the `font_awesome` gem installed which includes various helpers for ease of use. The `UiHelper` module automatically includes the appropriate icon in most cases, but can be overridden with arguments, if appropriate.

### 508-compliant HTML Attributes
If you happen to be familiar with 508 implementations, and know the correct HTML attributes to use (eg. `role`, `rel`, etc), please feel free to use these or update the `UiHelper` to use them.

## Filter Forms
Some pages have filters that allow mutating of the data collection in the page. These form controls should be confined to a `<section id="filters">` at the top of the page (see existing pages for examples). It should have both a button that applies the filter, as well as one that just loads the existing page, bare (`foos_path`).

# Tables
Please only use tables for displaying grids of data or displaying tabular outputs, not for doing layouts (particularly with forms).

## Table Rows
Table rows that offer contextual actions for each row should have an action buttons column, set to the far-right. This column does not need heading text.

## Table Heading
Each `<th>` tag in a `<thead>` should have `scope="col"`, and the first column's cells should also be `<th scope="row">`. For example:

```html
<table>
  <thead>
    <tr><th scope="col">Name</th><th scope="col">Address</th><th scope="col">Country</th></tr>
  </thead>
  <tbody>
    <tr><th scope="row">Adam</th><td>123 Anywhere Ave.</td><td>USA</td></tr>
    <tr><th scope="row">Betty</th><td>234 Somewhere St.</td><td>USA!</td></tr>
    <tr><th scope="row">Charlie</th><td>345 Lost Ln.</td><td>USA!!!</td></tr>
  </tbody>
</table>
```

# Page layouts
All pages should use one of the existing layouts.

 * `application.html.erb` - Normal pages for signed-in users
 * `devise.html.erb` - Used for Devise actions (password reset, sign-up, etc)
 * `mailer.html.erb` / `mailer.text.erb` - Used for mailer templates

## Navigation
The left-side navigation should reflect the local actions available to the current context. This is mainly scoped across "normal" organization users and "administrative" users. Additional contexts might be "guests" (users that are not authenticated), or "partners" (users that are internally known across the Diaper suite, but not expressly in an organization nor administrator)

These navigational choices should be implicitly included in the page layouts.

