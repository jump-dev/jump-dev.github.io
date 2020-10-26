---
title:  "Governance Structure"
---

This document describes the formal governance structure of the JuMP project.

For the purpose of this document, "JuMP" includes all repositories in the
[JuMP-dev Github organization].

## Mission

The mission of the JuMP project is to provide a free, open-source software stack
for mathematical optimization based on the JuMP modeling language.

## Code of Conduct

The JuMP community strongly values inclusivity and diversity. Everyone should
treat others with the utmost respect. Everyone in the community must adhere to
the [NumFOCUS Code of Conduct](https://numfocus.org/code-of-conduct) and the
[Julia Community Standards](https://julialang.org/community/standards/), which
reflect the values of our community. Both these links have information on how to
confidentially report a violation.

## Entities

This section outlines the different entities that exist within the JuMP project,
their basic role, and how membership of each entity is determined.

### Benevolent Dictator For Life

Due to his role in the creation of JuMP, [Miles Lubin](https://github.com/mlubin)
holds the title of [Benevolent Dictator For Life (BDFL)](https://en.wikipedia.org/wiki/Benevolent_dictator_for_life).

### Core Contributors

Core contributors lead the technical development of the JuMP project, and they
are the ultimate authority on the direction of the JuMP project.

The current core contributors are:

* Miles Lubin (@mlubin)
* Benoît Legat (@blegat)
* Joaquim Dias Garcia (@joaquimg)
* Joey Huchette (@joehuchette)
* Oscar Dowson (@odow)

A new core contributor may be added by consensus of the current core
contributors and notification to the [Steering Committee].

Before becoming a core contributor, it is expected that the community member is
a [repository maintainer](#repository-maintainers) of several repositories in
the [JuMP-dev Github organization].

### Emeritus Core Contributors

Emeritus core contributors are community members who were [core contributors],
but have stepped back to a less active role.

The emeritus core contributors are:

* Iain Dunning (@iainnz)

A [core contributor](#core-contributors) may choose to switch to emeritus status
by informing the other [core contributors] and the [Steering Committee].

### Repository Maintainers

Repository maintainers are trusted members of the community who help the [core
contributors] by managing a limited number of repositories in the [JuMP-dev
Github organization].

Any [core contributor](#core-contributors) has individual authority to appoint a
community member as a repository maintainer of a repository with notification to
the other [core contributors].

Before becoming a repository maintainer, it is expected that the community
member will have been an active participant in the development and maintenance
of a repository for a sustained period of time. This includes triaging issues,
proposing and reviewing pull requests, and updating any binary dependencies as
needed.

Community members may be maintainers of multiple repositories at the same time.

The list of repository maintainers is [available here](/pages/maintainers).

Repository maintainers can step back from their role at any time by informing a
[core contributor](#core-contributors). Furthermore, [core contributors], by
consensus, can choose to remove repository maintainers for any reason (typically
inactivity).

### NumFOCUS

JuMP is a [fiscally sponsored project of NumFOCUS](https://numfocus.org/project/jump),
a 501(c)(3) public charity in the United States. NumFOCUS provides JuMP with
fiscal, legal, and administrative support to help ensure the health and
sustainability of the project.

### Steering Committee

The Steering Committee supports the [core contributors] by representing JuMP in
all interactions with [NumFOCUS](#numfocus), e.g., by attending [NumFOCUS's
annual summit](https://numfocus.org/blog/numfocus-summit-2019). In addition, the
Steering Committee:

* Approves expenditures related to JuMP and paid through the NumFOCUS account.
* Negotiates and approves contracts between NumFOCUS and external contractors
  who provide paid work to JuMP.

The current members of the Steering Committee are:

* Miles Lubin, _Google_ (@mlubin)
* Juan Pablo Vielma, _Google_ (@juan-pablo-vielma)
* Joey Huchette, _Rice University_ (@joehuchette)
* Oscar Dowson (@odow)
* Changhyun Kwon, _U. South Florida_ (@chkwon)

A member of the Steering Committee may leave the committee by notifying the
Steering Committee and [core contributors]. The remaining Steering Committee
members, in consultation with the [core contributors], will invite a member of
the community to join in order to maintain a quorum of five members.

## Decision Making Process

This section outlines how financial and non-financial decisions are made in the
JuMP project.

### Financial Decisions

All financial decisions are made by the [Steering Committee] to ensure any funds
are spent in a manner that furthers the [mission](#mission) of JuMP. Financial
decisions require majority approval by [Steering Committee] members.

Community members proposing decisions with a financial aspect should contact the
[Steering Committee] directly, or table their proposal as an agenda item for
discussion on a [monthly developer call].

### Non-financial Decisions

All non-financial decisions are made via consensus of the [core contributors]
and relevant [repository maintainers]. [Emeritus core contributors](#emeritus-core-contributors)
are not considered to be [core contributors] for this purpose.

Code-related decisions, such when a pull request is ready to be accepted and
merged, should be discussed via the relevant Github issues and pull requests. If
consensus cannot be achieved, the community member proposing the change may be
invited by a [core contributor](#core-contributors) to present their proposal at
a [monthly developer call] for further discussion and community input.

Non-code-related decisions, such as long-term strategic planning for JuMP,
should either be discussed in a Github issue, or tabled as an agenda item and
discussed on a [monthly developer call].

If consensus on a non-financial decision cannot be achieved, the final decision
will be made by the [BDFL](#benevolent-dictator-for-life).

The [Steering Committee] can gain additional decision-making power if the [core
contributors] decide to delegate.

### Conflict of Interest

It is expected that community members will be employed at a wide range of
companies, universities and non-profit organizations. Because of this, it is
possible that members will have conflicts of interest. Such conflicts of
interest include, but are not limited to:

* Financial interests, such as investments, employment or contracting work,
  outside of JuMP that may influence their work on JuMP.
* Access to proprietary information of their employer that could potentially
  leak into their work with JuMP.

All members of the [Steering Committee] shall disclose to the [Steering
Committee] any conflict of interest they may have. Members with a conflict of
interest in a particular issue may participate in [Steering Committee]
discussions on that issue, but must recuse themselves from voting.

[Core contributors](#core-contributors) and [repository maintainers] should also
disclose conflicts of interest with other [core contributors] and step back from
decisions when conflicts of interests are in play.

## Github Permissions

[Github permissions][permissions] are used to control access to repositories in
the [JuMP-dev Github organization].

Anyone with commit access to a repository is trusted to use it in a way that is
consistent with the [Decision Making Process](#decision-making-process).
Those with permissions should prefer pull requests over direct pushes, ask for
feedback on changes if they are not sure there is a consensus, and follow JuMP's
[style guide](https://jump.dev/JuMP.jl/stable/style/) and development processes.

### Core Contributors

[Core contributors](#core-contributors) are added as [Owners][owner-permission]
of the [JuMP-dev Github organization] and have [Admin][permissions] permission
to every repository.

### Emeritus Core Contributors

[Emeritus core contributors](#emeritus-core-contributors) retain the same commit
rights as [core contributors], unless they choose to surrender them.

### Repository Maintainers

[Repository maintainers](#repository-maintainers) have [Maintain][permissions]
rights to an individual repository as an outside collaborator. Among other
rights, this allows them to push code to a branch in the
[JuMP-dev Github organization] instead of their personal fork, merge pull
requests, and close issues.

## Community Involvement

The JuMP project highly values the contributions made by members of the
community. As an open-source project, JuMP is both made for the community, and
by the community.

There are five main channels that JuMP uses to engage with the community.

### Community Forum

The community forum is a place for community members to post questions and
receive help.

The current forum is the ["Optimization (Mathematical)" section of the
Julia Discourse Forum](https://discourse.julialang.org/c/domain/opt/13).

### Developer Chatroom

The developer chatroom is a chatroom for developer-focused discussions about
JuMP.

The current chatroom is the [JuMP-dev Gitter channel](https://gitter.im/JuliaOpt/JuMP-dev).

### Monthly Developer Call

The [Steering Committee] hosts a monthly developer call to discuss JuMP-related
business.

The calls are currently scheduled on the fourth Thursday of every month at 14:00
Eastern. For information on how to take part, join the [developer chatroom] and
ask `@odow` or `@mlubin` for an invite to the monthly developer call.

The invite contains information on how to table agenda items for upcoming calls.

### JuMP-dev Workshops

The [Steering Committee] will periodically choose a Chair to organize a JuMP-dev
workshop.

Previous workshops include [Santiago, 2019](https://jump.dev/meetings/santiago2019/),
[Bordeaux, 2018](https://jump.dev/meetings/bordeaux2018/), and [Boston, 2017](https://jump.dev/meetings/mit2017/).

Announcements of future workshops will be communicated through the
[community forum], [social media](#social-media), and via the
[jump.dev](https://jump.dev) website.

### Social Media

The JuMP Twitter handle is [@JuMPjl](https://twitter.com/JuMPjl).

## Transferring repositories to jump-dev

The [JuMP-dev Github organization] exists to simplify the management of Github
permissions on JuMP-related repositories. It is not a curation of all
JuMP-compatible solvers and supporting packages.

Instead, community members who develop new pure-Julia solvers or solver-wrappers
should first add their package to the list of supported solvers in the
[Installation Guide](https://jump.dev/JuMP.jl/stable/installation/#Getting-Solvers-1)
of the JuMP documentation.

Note that when developing a new solver or JuMP-extension, the [core
contributors] request that you do not use "JuMP" in the name without prior
consent.

Even once a package has matured, the bar for transferring repositories to the
[JuMP-dev Github organization] is high, and can be summarized by the following:

* The maintenance of the package would be simplified if [core contributors]
  have [Admin permission][permissions] to the repository.

Community members wishing to transfer a repository from their personal account
to the [JuMP-dev Github organization] should contact the [core contributors]
via the [developer chatroom].

[JuMP-dev Github organization]: https://github.com/jump-dev
[permissions]: https://docs.github.com/en/free-pro-team@latest/github/setting-up-and-managing-organizations-and-teams/repository-permission-levels-for-an-organization#repository-access-for-each-permission-level
[owner-permission]: https://docs.github.com/en/free-pro-team@latest/github/setting-up-and-managing-organizations-and-teams/permission-levels-for-an-organization#permission-levels-for-an-organization

[community forum]: #community-forum
[developer chatroom]: #developer-chatroom
[core contributors]: #core-contributors
[repository maintainers]: #repository-maintainers
[Steering Committee]: #steering-committee
[monthly developer call]: #monthly-developer-call
