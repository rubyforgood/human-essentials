# Human Essentials
<p align="center">
<a href="https://app.digitalpublicgoods.net/a/10622">
<img src="https://user-images.githubusercontent.com/667909/181150972-e59a77ab-b657-4893-aef9-d3df1384a506.png" alt="DPG Approved" height="40">
</a>
</p>

<!-- ALL-CONTRIBUTORS-BADGE - Do not remove or modify -->

<p>
<a href="https://img.shields.io/badge/all_contributors-115-orange.svg?logo=github" alt="All contributors"><img src="https://img.shields.io/badge/all_contributors-115-orange.svg?logo=github" /></a>
<a href="https://app.fossa.com/api/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper.svg?type=shield" alt="license scan"><img src="https://app.fossa.com/api/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper.svg?type=shield" /></a>
<a href="https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20Rspec%20tests-%230074ff" alt="Knapsack Pro Parallel CI builds for RSpec tests"><img src="https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20Rspec%20tests-%230074ff" /></a>
<a href="https://github.com/rubyforgood/human-essentials/graphs/contributors" alt="Contributors"> <img src="https://img.shields.io/github/contributors/rubyforgood/human-essentials?logo=github" /></a>
<a href="https://github.com/rubyforgood/human-essentials/issues" alt="Contributors"> <img src="https://img.shields.io/github/issues-closed/rubyforgood/human-essentials?logo=github" /></a>
<a href="https://github.com/rubyforgood/human-essentials/search" alt="Languages"><img src="https://img.shields.io/github/languages/count/rubyforgood/human-essentials?logo=github" /></a>
<a href="https://github.com/rubyforgood/human-essentials/search" alt="Languages"><img src="https://img.shields.io/github/languages/top/rubyforgood/human-essentials?logo=github" /></a>
<a href="https://github.com/rubyforgood/human-essentials/ alt="Size"><img src="https://img.shields.io/github/repo-size/rubyforgood/human-essentials?logo=github" /></a>
<a href="https://github.com/rubyforgood/human-essentials/pulls" alt="Pull Requests"><img src="https://img.shields.io/github/issues-pr-closed-raw/rubyforgood/human-essentials?logo=github" /></a>
<a href="https://github.com/rubyforgood/human-essentials/ alt="LICENSE"><img src="https://badgen.net/github/license/rubyforgood/human-essentials?icon=github&color=green" /></a>
<a href="https://github.com/badges/shields/pulse" alt="Activity"><img src="https://img.shields.io/github/commit-activity/m/rubyforgood/human-essentials?logo=github" /></a>
<a href="https://github.com/rubyforgood/human-essentials/commits/main" alt="Last Commit"><img src="https://img.shields.io/github/last-commit/rubyforgood/human-essentials?logo=github" /></a>
<a href="https://github.com/rubyforgood/human-essentials/commits/main" alt="Total Commits"><img src="https://badgen.net/github/commits/rubyforgood/human-essentials/main?icon=github&color=green" /></a>
</p>

<p align="center">
<a href="https://github.com/rubyforgood/human-essentials/" alt="Stars"><img src="https://img.shields.io/github/stars/rubyforgood/human-essentials?style=social" /></a>
<a href="https://github.com/rubyforgood/human-essentials/" alt="Forks"><img src="https://img.shields.io/github/forks/rubyforgood/human-essentials?style=social" /></a>
<a href="https://github.com/rubyforgood/human-essentials/" alt="Watchers"><img src="https://img.shields.io/github/watchers/rubyforgood/human-essentials?style=social" /></a>
</p>

## Mission 💖

Human Essentials is an inventory management system built to address the needs of [Diaper Banks](https://nationaldiaperbanknetwork.org/diaper-need/) as directly and explicitly as possible and adapted to meet the needs of other Essentials Banks. Essentials Banks maintain inventory, receive donations and other human essentials supplies (e.g. diapers, period supplies), and issue distributions to community partner organizations. Like any non-profit, they also need to perform reports on this data and have day-to-day operational information they need. This application aims to serve those needs and facilitate the general operations of the Diaper Banks (e.g., using barcode readers, scale weighing, inventory audits).

## Impact 🌟

Human Essentials has over 200 registered banks across the United States at **no cost** to them. It is currently helping over **3 million** children receive diapers and over **400k** period supply recipients receive period supplies. Our team is in partnership with the [National Diaper Bank Network (NDBN)](https://nationaldiaperbanknetwork.org/) and can be found in their annual conference that brings numerous of non-profit organizations that distribute essential products to people.

We are proud of our achievements up to date but there is much more to do! This is where you come in...

## Ruby for Good

Human Essentials is one of many projects initiated and run by Ruby for Good. You can find out more about Ruby for Good at https://rubyforgood.org

## Digital Public Good 🎉

The [Digital Public Goods Alliance](https://digitalpublicgoods.net/registry/) recognizes Human Essentials as a digital public good (DPG). This project supports the following Sustainable Development Goals:
* [SDG 1](https://sdgs.un.org/goals/goal1) - End poverty in all its forms everywhere
* [SDG 3](https://sdgs.un.org/goals/goal3) - Ensure healthy lives and promote well-being for all at all ages
* [SDG 10](https://sdgs.un.org/goals/goal10) - Reduce inequality within and among countries

Use as an Organization or Contribute as an Individual/Team to this Project:
- [NGO Adoption Info](ngo.md) - information about how to use this DPG
- [Skills Based Volunteering Info](sbv.md) - information about how to volunteer

## Welcome Contributors! 👋

Thanks for checking us out! Check out our [Contributing Guidelines](https://github.com/rubyforgood/human-essentials/blob/main/CONTRIBUTING.md) on how to contribute.

## Deployment Process
The human-essentials & partner application should ideally be deployed on a weekly or bi-weekly schedule depending on the merged updates in the main branch. This is the process we take to deploy updates from our main branch to our servers.

### Requirements
- SSH access to our servers (usually granted to core maintainers)
- Login credentials to our [Mailchimp](https://mailchimp.com/) account

### Steps
#### 1. Merge main into production branch 
All deploys deploy from the production branch, which keeps track of what is currently in production.

```sh
git checkout production
git merge main
```

#### 2. Tag & Release
1. Push a tag with the appropriate date versioning. Refer to the [releases](https://github.com/rubyforgood/human-essentials/releases) for the correct versioning. For example, if you are deploying on June 23, 2024:

    ```sh
    git tag 2024.06.23
    git push origin tag 2024.06.23
    ```
2. Publish a release, associated to that tag pushed up in the previous step, [here](https://github.com/rubyforgood/human-essentials/releases/new). Include details about the release's updates (we use this to notify our stakeholders on updates via email).

### Running delayed jobs

Run delayed jobs locally with the `rake jobs:work` command. This is necessary to view any emails in your browser. Alternatively, you can run a specific delayed job by opening a Rails console and doing something like:

```ruby
Delayed::Job.last.invoke_job
```

You can replace the `last` query with any other query (e.g. `Delayed::Job.find(123)`).

# Acknowledgements
Thanks to Rachel (from PDX Diaperbank) for all of her insight, support, and assistance with this application, and Sarah ( http://www.sarahkasiske.com/ ) for her wonderful design and CSS work at Ruby For Good '17!

# License
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Frubyforgood%2Fdiaper?ref=badge_large)

# ✨ Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/edwinthinks"><img src="https://avatars.githubusercontent.com/u/11335191?v=4?s=100" width="100px;" alt="Edwin Mak"/><br /><sub><b>Edwin Mak</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=edwinthinks" title="Code">💻</a> <a href="#projectManagement-edwinthinks" title="Project Management">📆</a> <a href="#infra-edwinthinks" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#ideas-edwinthinks" title="Ideas, Planning, & Feedback">🤔</a> <a href="#question-edwinthinks" title="Answering Questions">💬</a> <a href="#security-edwinthinks" title="Security">🛡️</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://rubyforgood.org/"><img src="https://avatars.githubusercontent.com/u/667909?v=4?s=100" width="100px;" alt="Sean Marcia"/><br /><sub><b>Sean Marcia</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=seanmarcia" title="Code">💻</a> <a href="#business-seanmarcia" title="Business development">💼</a> <a href="#financial-seanmarcia" title="Financial">💵</a> <a href="#fundingFinding-seanmarcia" title="Funding Finding">🔍</a> <a href="#eventOrganizing-seanmarcia" title="Event Organizing">📋</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://armahillo.dev/"><img src="https://avatars.githubusercontent.com/u/502363?v=4?s=100" width="100px;" alt="Aaron H"/><br /><sub><b>Aaron H</b></sub></a><br /><a href="#projectManagement-armahillo" title="Project Management">📆</a> <a href="https://github.com/rubyforgood/human-essentials/commits?author=armahillo" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://gitlab.com/IlinDmitry"><img src="https://avatars.githubusercontent.com/u/13395396?v=4?s=100" width="100px;" alt="Dmitry"/><br /><sub><b>Dmitry</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=IlinDmitry" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://adambachman.org/"><img src="https://avatars.githubusercontent.com/u/13002?v=4?s=100" width="100px;" alt="Adam Bachman"/><br /><sub><b>Adam Bachman</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=abachman" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jcavena"><img src="https://avatars.githubusercontent.com/u/200333?v=4?s=100" width="100px;" alt="JC Avena"/><br /><sub><b>JC Avena</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jcavena" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mdworken"><img src="https://avatars.githubusercontent.com/u/31595784?v=4?s=100" width="100px;" alt="mdworken"/><br /><sub><b>mdworken</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=mdworken" title="Code">💻</a> <a href="#projectManagement-mdworken" title="Project Management">📆</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mlpinit"><img src="https://avatars.githubusercontent.com/u/1443346?v=4?s=100" width="100px;" alt="Marius Pop"/><br /><sub><b>Marius Pop</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=mlpinit" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ejuten"><img src="https://avatars.githubusercontent.com/u/10624016?v=4?s=100" width="100px;" alt="Elayne"/><br /><sub><b>Elayne</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=ejuten" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/duaimei"><img src="https://avatars.githubusercontent.com/u/7873934?v=4?s=100" width="100px;" alt="Amy Detwiler"/><br /><sub><b>Amy Detwiler</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=duaimei" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/designbygia"><img src="https://avatars.githubusercontent.com/u/56228717?v=4?s=100" width="100px;" alt="Gia"/><br /><sub><b>Gia</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=designbygia" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://medium.com/@adewusi"><img src="https://avatars.githubusercontent.com/u/42121379?v=4?s=100" width="100px;" alt="Amina Adewusi"/><br /><sub><b>Amina Adewusi</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=Nirvikalpa108" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/albertchae"><img src="https://avatars.githubusercontent.com/u/217050?v=4?s=100" width="100px;" alt="albertchae"/><br /><sub><b>albertchae</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=albertchae" title="Code">💻</a> <a href="#ideas-albertchae" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/cattywampus"><img src="https://avatars.githubusercontent.com/u/1625840?v=4?s=100" width="100px;" alt="Keith Walters"/><br /><sub><b>Keith Walters</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=cattywampus" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://southard.dev/"><img src="https://avatars.githubusercontent.com/u/7292?v=4?s=100" width="100px;" alt="Chase Southard"/><br /><sub><b>Chase Southard</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=chaserx" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://thelackthereof.org/"><img src="https://avatars.githubusercontent.com/u/8642?v=4?s=100" width="100px;" alt="Brock Wilcox"/><br /><sub><b>Brock Wilcox</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=awwaiid" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/danquill"><img src="https://avatars.githubusercontent.com/u/16866776?v=4?s=100" width="100px;" alt="danquill"/><br /><sub><b>danquill</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=danquill" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://www.bbs-software.com/"><img src="https://avatars.githubusercontent.com/u/28410?v=4?s=100" width="100px;" alt="Keith Bennett"/><br /><sub><b>Keith Bennett</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=keithrbennett" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/benreyn"><img src="https://avatars.githubusercontent.com/u/11561578?v=4?s=100" width="100px;" alt="Benjamin Reynolds"/><br /><sub><b>Benjamin Reynolds</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=benreyn" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jtu0"><img src="https://avatars.githubusercontent.com/u/4042423?v=4?s=100" width="100px;" alt="jtu0"/><br /><sub><b>jtu0</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jtu0" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://www.linkedin.com/in/juarezlustosa"><img src="https://avatars.githubusercontent.com/u/505372?v=4?s=100" width="100px;" alt="Juarez Lustosa"/><br /><sub><b>Juarez Lustosa</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=JuarezLustosa" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/JulienAmoros"><img src="https://avatars.githubusercontent.com/u/17905578?v=4?s=100" width="100px;" alt="Julien A."/><br /><sub><b>Julien A.</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=JulienAmoros" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/EmersonManabuAraki"><img src="https://avatars.githubusercontent.com/u/26900611?v=4?s=100" width="100px;" alt="Emerson Manabu Araki"/><br /><sub><b>Emerson Manabu Araki</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=EmersonManabuAraki" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://powerhrg.com/"><img src="https://avatars.githubusercontent.com/u/167131?v=4?s=100" width="100px;" alt="Ben Klang"/><br /><sub><b>Ben Klang</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=bklang" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/karolina-benitez"><img src="https://avatars.githubusercontent.com/u/28552912?v=4?s=100" width="100px;" alt="karolina"/><br /><sub><b>karolina</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=karolina-benitez" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/joshcano"><img src="https://avatars.githubusercontent.com/u/5419597?v=4?s=100" width="100px;" alt="Josh Cano"/><br /><sub><b>Josh Cano</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=joshcano" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/sbpipb"><img src="https://avatars.githubusercontent.com/u/2242652?v=4?s=100" width="100px;" alt="Julian Macmang"/><br /><sub><b>Julian Macmang</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=sbpipb" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/PhilipDeFraties"><img src="https://avatars.githubusercontent.com/u/65036872?v=4?s=100" width="100px;" alt="Philip DeFraties"/><br /><sub><b>Philip DeFraties</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=PhilipDeFraties" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/GabrielRMuller"><img src="https://avatars.githubusercontent.com/u/33486409?v=4?s=100" width="100px;" alt="GabrielRMuller"/><br /><sub><b>GabrielRMuller</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=GabrielRMuller" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://luchiago.github.io/"><img src="https://avatars.githubusercontent.com/u/30028621?v=4?s=100" width="100px;" alt="Lucas Hiago"/><br /><sub><b>Lucas Hiago</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=luchiago" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/chiefkikio"><img src="https://avatars.githubusercontent.com/u/3259878?v=4?s=100" width="100px;" alt="Lanya Butler"/><br /><sub><b>Lanya Butler</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=chiefkikio" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://edumoreira1506.github.io/blog"><img src="https://avatars.githubusercontent.com/u/49662698?v=4?s=100" width="100px;" alt="Eduardo Moreira"/><br /><sub><b>Eduardo Moreira</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=edumoreira1506" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://aliciabarrett.dev/"><img src="https://avatars.githubusercontent.com/u/13841769?v=4?s=100" width="100px;" alt="Alicia Barrett"/><br /><sub><b>Alicia Barrett</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=Aliciawyse" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://www.forchaengineering.com/"><img src="https://avatars.githubusercontent.com/u/4605789?v=4?s=100" width="100px;" alt="Bob Forcha"/><br /><sub><b>Bob Forcha</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=bobforcha" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://willmurphyscode.net/"><img src="https://avatars.githubusercontent.com/u/12529630?v=4?s=100" width="100px;" alt="William Murphy"/><br /><sub><b>William Murphy</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=willmurphyscode" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="http://www.katelovescode.com/"><img src="https://avatars.githubusercontent.com/u/8364647?v=4?s=100" width="100px;" alt="Kate Donaldson"/><br /><sub><b>Kate Donaldson</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=katelovescode" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://matthewdodds.com/"><img src="https://avatars.githubusercontent.com/u/1717864?v=4?s=100" width="100px;" alt="Matthew Russell Dodds"/><br /><sub><b>Matthew Russell Dodds</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=MatthewRDodds" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://www.daydreamsinruby.com/"><img src="https://avatars.githubusercontent.com/u/2354079?v=4?s=100" width="100px;" alt="Allison McMillan"/><br /><sub><b>Allison McMillan</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=asheren" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/a-jean"><img src="https://avatars.githubusercontent.com/u/9901121?v=4?s=100" width="100px;" alt="Ashley Jean"/><br /><sub><b>Ashley Jean</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=a-jean" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jeduardo824"><img src="https://avatars.githubusercontent.com/u/27960597?v=4?s=100" width="100px;" alt="Eduardo Alencar"/><br /><sub><b>Eduardo Alencar</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jeduardo824" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://www.thomashart.me/"><img src="https://avatars.githubusercontent.com/u/3099915?v=4?s=100" width="100px;" alt="Thomas Hart"/><br /><sub><b>Thomas Hart</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=myrridin" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/viamin"><img src="https://avatars.githubusercontent.com/u/260794?v=4?s=100" width="100px;" alt="Bart Agapinan"/><br /><sub><b>Bart Agapinan</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=viamin" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/NiquiCara"><img src="https://avatars.githubusercontent.com/u/45127691?v=4?s=100" width="100px;" alt="Monique"/><br /><sub><b>Monique</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=NiquiCara" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://valerie.codes/"><img src="https://avatars.githubusercontent.com/u/5439589?v=4?s=100" width="100px;" alt="Valerie Woolard"/><br /><sub><b>Valerie Woolard</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=valeriecodes" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/zak-kay"><img src="https://avatars.githubusercontent.com/u/79330383?v=4?s=100" width="100px;" alt="zak-kay"/><br /><sub><b>zak-kay</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=zak-kay" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jjlahatte"><img src="https://avatars.githubusercontent.com/u/35351407?v=4?s=100" width="100px;" alt="Jason LaHatte"/><br /><sub><b>Jason LaHatte</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jjlahatte" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/davetapley"><img src="https://avatars.githubusercontent.com/u/48232?v=4?s=100" width="100px;" alt="Dave Tapley"/><br /><sub><b>Dave Tapley</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=davetapley" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Megchan"><img src="https://avatars.githubusercontent.com/u/11429067?v=4?s=100" width="100px;" alt="Meghan"/><br /><sub><b>Meghan</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=Megchan" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/dropkickfish"><img src="https://avatars.githubusercontent.com/u/33702528?v=4?s=100" width="100px;" alt="Andy Thackray"/><br /><sub><b>Andy Thackray</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=dropkickfish" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/felipelovato"><img src="https://avatars.githubusercontent.com/u/2296173?v=4?s=100" width="100px;" alt="Felipe Lovato Flores"/><br /><sub><b>Felipe Lovato Flores</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=felipelovato" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/marcelkooi"><img src="https://avatars.githubusercontent.com/u/13142719?v=4?s=100" width="100px;" alt="Marcel Kooi"/><br /><sub><b>Marcel Kooi</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=marcelkooi" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://leesharma.com/"><img src="https://avatars.githubusercontent.com/u/814638?v=4?s=100" width="100px;" alt="Lee Sharma"/><br /><sub><b>Lee Sharma</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=leesharma" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/scooter-dangle"><img src="https://avatars.githubusercontent.com/u/934707?v=4?s=100" width="100px;" alt="Scott Steele"/><br /><sub><b>Scott Steele</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=scooter-dangle" title="Code">💻</a> <a href="#ideas-scooter-dangle" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://www.sam-we.com/"><img src="https://avatars.githubusercontent.com/u/10361390?v=4?s=100" width="100px;" alt="Sam Weerasinghe"/><br /><sub><b>Sam Weerasinghe</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=oystersauce8" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/gerald"><img src="https://avatars.githubusercontent.com/u/46204?v=4?s=100" width="100px;" alt="Gerald Abrencillo"/><br /><sub><b>Gerald Abrencillo</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=gerald" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/rodolfoasantos"><img src="https://avatars.githubusercontent.com/u/754389?v=4?s=100" width="100px;" alt="Rodolfo Santos"/><br /><sub><b>Rodolfo Santos</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=rodolfoasantos" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://www.linkedin.com/in/gabrielbaldao/"><img src="https://avatars.githubusercontent.com/u/20587352?v=4?s=100" width="100px;" alt="Gabriel Baldão"/><br /><sub><b>Gabriel Baldão</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=gabrielbaldao" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/melaniew"><img src="https://avatars.githubusercontent.com/u/1447452?v=4?s=100" width="100px;" alt="Melanie White"/><br /><sub><b>Melanie White</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=melaniew" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/holytoastr"><img src="https://avatars.githubusercontent.com/u/4822313?v=4?s=100" width="100px;" alt="Melissa Miller"/><br /><sub><b>Melissa Miller</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=holytoastr" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/marcheiligers"><img src="https://avatars.githubusercontent.com/u/173701?v=4?s=100" width="100px;" alt="Marc Heiligers"/><br /><sub><b>Marc Heiligers</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=marcheiligers" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/josephbhunt"><img src="https://avatars.githubusercontent.com/u/78151?v=4?s=100" width="100px;" alt="Joe Hunt"/><br /><sub><b>Joe Hunt</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=josephbhunt" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/meg-gutshall"><img src="https://avatars.githubusercontent.com/u/37842352?v=4?s=100" width="100px;" alt="Meg Gutshall"/><br /><sub><b>Meg Gutshall</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=meg-gutshall" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ozydingo"><img src="https://avatars.githubusercontent.com/u/4616431?v=4?s=100" width="100px;" alt="Andrew H Schwartz"/><br /><sub><b>Andrew H Schwartz</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=ozydingo" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://www.turing.io/alumni/joseph-glass"><img src="https://avatars.githubusercontent.com/u/17987273?v=4?s=100" width="100px;" alt="Joseph Glass"/><br /><sub><b>Joseph Glass</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=glassjoseph" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://reesew.io/"><img src="https://avatars.githubusercontent.com/u/26661872?v=4?s=100" width="100px;" alt="Reese Williams"/><br /><sub><b>Reese Williams</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=reese" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/perezperret"><img src="https://avatars.githubusercontent.com/u/4761084?v=4?s=100" width="100px;" alt="Santiago Perez"/><br /><sub><b>Santiago Perez</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=perezperret" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/SiriusDely"><img src="https://avatars.githubusercontent.com/u/511437?v=4?s=100" width="100px;" alt="Sirius Dely"/><br /><sub><b>Sirius Dely</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=SiriusDely" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://heatherherrington.github.io/"><img src="https://avatars.githubusercontent.com/u/17165242?v=4?s=100" width="100px;" alt="Heather Herrington"/><br /><sub><b>Heather Herrington</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=heatherherrington" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/moacirguedes"><img src="https://avatars.githubusercontent.com/u/11277348?v=4?s=100" width="100px;" alt="Moacir Guedes"/><br /><sub><b>Moacir Guedes</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=moacirguedes" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/CraigJZ"><img src="https://avatars.githubusercontent.com/u/7053190?v=4?s=100" width="100px;" alt="CraigJZ"/><br /><sub><b>CraigJZ</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=CraigJZ" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://www.linkedin.com/in/semiharslanoglu/"><img src="https://avatars.githubusercontent.com/u/10260283?v=4?s=100" width="100px;" alt="Semih Arslanoğlu"/><br /><sub><b>Semih Arslanoğlu</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=sarslanoglu" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/m-pereira"><img src="https://avatars.githubusercontent.com/u/47258878?v=4?s=100" width="100px;" alt="Mauricio de Lima"/><br /><sub><b>Mauricio de Lima</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=m-pereira" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/dacur"><img src="https://avatars.githubusercontent.com/u/4250366?v=4?s=100" width="100px;" alt="David Curtis"/><br /><sub><b>David Curtis</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=dacur" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/nataliagalan"><img src="https://avatars.githubusercontent.com/u/66537500?v=4?s=100" width="100px;" alt="Natalia Galán"/><br /><sub><b>Natalia Galán</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=nataliagalan" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://andersonfernandes.dev/"><img src="https://avatars.githubusercontent.com/u/8173530?v=4?s=100" width="100px;" alt="Anderson Fernandes"/><br /><sub><b>Anderson Fernandes</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=andersonfernandes" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/belgamo"><img src="https://avatars.githubusercontent.com/u/19699724?v=4?s=100" width="100px;" alt="Gabriel Belgamo"/><br /><sub><b>Gabriel Belgamo</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=belgamo" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jorgedjr21"><img src="https://avatars.githubusercontent.com/u/4561599?v=4?s=100" width="100px;" alt="Jorge David C.T Junior"/><br /><sub><b>Jorge David C.T Junior</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jorgedjr21" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/SethLieberman"><img src="https://avatars.githubusercontent.com/u/16119691?v=4?s=100" width="100px;" alt="Seth Lieberman"/><br /><sub><b>Seth Lieberman</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=SethLieberman" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jsantos"><img src="https://avatars.githubusercontent.com/u/32199?v=4?s=100" width="100px;" alt="Jorge Oliveira Santos"/><br /><sub><b>Jorge Oliveira Santos</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=jsantos" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://www.dandrinkard.com/"><img src="https://avatars.githubusercontent.com/u/72645?v=4?s=100" width="100px;" alt="Drinks"/><br /><sub><b>Drinks</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=drinks" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/brunohkbx"><img src="https://avatars.githubusercontent.com/u/6487206?v=4?s=100" width="100px;" alt="Bruno Castro"/><br /><sub><b>Bruno Castro</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=brunohkbx" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://xjunior.me/"><img src="https://avatars.githubusercontent.com/u/8156?v=4?s=100" width="100px;" alt="Carlos Palhares"/><br /><sub><b>Carlos Palhares</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=xjunior" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://nepalmap.org/"><img src="https://avatars.githubusercontent.com/u/3824492?v=4?s=100" width="100px;" alt="Clifton McIntosh"/><br /><sub><b>Clifton McIntosh</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=cliftonmcintosh" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Beigelman"><img src="https://avatars.githubusercontent.com/u/50420424?v=4?s=100" width="100px;" alt="Daniel Beigelman"/><br /><sub><b>Daniel Beigelman</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=Beigelman" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/lmegviar"><img src="https://avatars.githubusercontent.com/u/23217560?v=4?s=100" width="100px;" alt="Meg Viar"/><br /><sub><b>Meg Viar</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=lmegviar" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/svileshina"><img src="https://avatars.githubusercontent.com/u/7723308?v=4?s=100" width="100px;" alt="Svetlana Vileshina"/><br /><sub><b>Svetlana Vileshina</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=svileshina" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/bpr3p"><img src="https://avatars.githubusercontent.com/u/43351221?v=4?s=100" width="100px;" alt="Ben Reed"/><br /><sub><b>Ben Reed</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=bpr3p" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/egiurleo"><img src="https://avatars.githubusercontent.com/u/9601737?v=4?s=100" width="100px;" alt="Emily Giurleo"/><br /><sub><b>Emily Giurleo</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=egiurleo" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/alemtgetu"><img src="https://avatars.githubusercontent.com/u/36018687?v=4?s=100" width="100px;" alt="Alem Getu"/><br /><sub><b>Alem Getu</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=alemtgetu" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/dejanbj"><img src="https://avatars.githubusercontent.com/u/7805837?v=4?s=100" width="100px;" alt="Dejan Bjeloglav"/><br /><sub><b>Dejan Bjeloglav</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=dejanbj" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/cassianoblonski"><img src="https://avatars.githubusercontent.com/u/9721558?v=4?s=100" width="100px;" alt="Cassiano Blonski Sampaio"/><br /><sub><b>Cassiano Blonski Sampaio</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=cassianoblonski" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/gdombchik"><img src="https://avatars.githubusercontent.com/u/7111708?v=4?s=100" width="100px;" alt="Greg"/><br /><sub><b>Greg</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=gdombchik" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/finn2d"><img src="https://avatars.githubusercontent.com/u/84066080?v=4?s=100" width="100px;" alt="finn"/><br /><sub><b>finn</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=finn2d" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://jaysonmandani.github.io/"><img src="https://avatars.githubusercontent.com/u/1963153?v=4?s=100" width="100px;" alt="Jayson Mandani"/><br /><sub><b>Jayson Mandani</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=JaysonMandani" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/stanleypliu"><img src="https://avatars.githubusercontent.com/u/53650048?v=4?s=100" width="100px;" alt="Stanley Liu"/><br /><sub><b>Stanley Liu</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=stanleypliu" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/c-bartell"><img src="https://avatars.githubusercontent.com/u/60277914?v=4?s=100" width="100px;" alt="Curtis Bartell"/><br /><sub><b>Curtis Bartell</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=c-bartell" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/librod89"><img src="https://avatars.githubusercontent.com/u/4965672?v=4?s=100" width="100px;" alt="Libby Rodriguez"/><br /><sub><b>Libby Rodriguez</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=librod89" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/joshuacgraves"><img src="https://avatars.githubusercontent.com/u/53875700?v=4?s=100" width="100px;" alt="joshuacgraves"/><br /><sub><b>joshuacgraves</b></sub></a><br /><a href="#question-joshuacgraves" title="Answering Questions">💬</a> <a href="#projectManagement-joshuacgraves" title="Project Management">📆</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://focused-wescoff-bfb488.netlify.app/"><img src="https://avatars.githubusercontent.com/u/65963997?v=4?s=100" width="100px;" alt="Himanshu"/><br /><sub><b>Himanshu</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=himanshu007-creator" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/MohamedHegab"><img src="https://avatars.githubusercontent.com/u/7612401?v=4?s=100" width="100px;" alt="Mohamed Hegab"/><br /><sub><b>Mohamed Hegab</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=MohamedHegab" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://kinduff.com"><img src="https://avatars.githubusercontent.com/u/1270156?v=4?s=100" width="100px;" alt="Alejandro AR"/><br /><sub><b>Alejandro AR</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=kinduff" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/hatsu38"><img src="https://avatars.githubusercontent.com/u/16137809?v=4?s=100" width="100px;" alt="hatsu"/><br /><sub><b>hatsu</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=hatsu38" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/matt-glover"><img src="https://avatars.githubusercontent.com/u/850480?v=4?s=100" width="100px;" alt="Matt Glover"/><br /><sub><b>Matt Glover</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=matt-glover" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/js-sapphire"><img src="https://avatars.githubusercontent.com/u/41758940?v=4?s=100" width="100px;" alt="js-sapphire"/><br /><sub><b>js-sapphire</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=js-sapphire" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/exbinary"><img src="https://avatars.githubusercontent.com/u/8330?v=4?s=100" width="100px;" alt="lasitha"/><br /><sub><b>lasitha</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=exbinary" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/patmccler"><img src="https://avatars.githubusercontent.com/u/28073714?v=4?s=100" width="100px;" alt="Patrick McClernan"/><br /><sub><b>Patrick McClernan</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=patmccler" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/marc"><img src="https://avatars.githubusercontent.com/u/725?v=4?s=100" width="100px;" alt="Marc Bellingrath"/><br /><sub><b>Marc Bellingrath</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=marc" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/dorner"><img src="https://avatars.githubusercontent.com/u/1986893?v=4?s=100" width="100px;" alt="Daniel Orner"/><br /><sub><b>Daniel Orner</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=dorner" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/bobmazanec"><img src="https://avatars.githubusercontent.com/u/2031462?v=4?s=100" width="100px;" alt="Bob Mazanec"/><br /><sub><b>Bob Mazanec</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=bobmazanec" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://www.linkedin.com/in/markcyen/"><img src="https://avatars.githubusercontent.com/u/77414433?v=4?s=100" width="100px;" alt="Mark Yen"/><br /><sub><b>Mark Yen</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=markcyen" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://twitch.tv/ChaelCodes"><img src="https://avatars.githubusercontent.com/u/8124558?v=4?s=100" width="100px;" alt="Rachael Wright-Munn"/><br /><sub><b>Rachael Wright-Munn</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=ChaelCodes" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/italomatos"><img src="https://avatars.githubusercontent.com/u/836472?v=4?s=100" width="100px;" alt="Ítalo Matos"/><br /><sub><b>Ítalo Matos</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=italomatos" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/heyapricot"><img src="https://avatars.githubusercontent.com/u/14355495?v=4?s=100" width="100px;" alt="Alvaro Sanchez Diaz"/><br /><sub><b>Alvaro Sanchez Diaz</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=heyapricot" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mbrundige"><img src="https://avatars.githubusercontent.com/u/16763501?v=4?s=100" width="100px;" alt="mbrundige"/><br /><sub><b>mbrundige</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=mbrundige" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://robgreene.dev"><img src="https://avatars.githubusercontent.com/u/65237366?v=4?s=100" width="100px;" alt="Robert Greene"/><br /><sub><b>Robert Greene</b></sub></a><br /><a href="https://github.com/rubyforgood/human-essentials/commits?author=confused-cabbage" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
