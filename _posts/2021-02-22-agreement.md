---
layout: post
title:  "NumFOCUS signs agreement with MIT to provide ongoing maintenance and support"
date:   2021-02-22
categories: [announcements]
---

The [JuMP Steering Committee](/pages/governance/#steering-committee) is pleased
to announce that we, through [NumFOCUS](https://numfocus.org), have signed an
agreement with [MIT](https://mit.edu) to provide ongoing maintenance and
support of JuMP as part of the
[National Science Foundation award OAC1835443](https://nsf.gov/awardsearch/showAward?AWD_ID=1835443&HistoricalAwards=false).
The agreement may be renewed on an annual basis through December 2023.

At a high-level, the agreement covers work that is focused on improving the
long-term sustainability of the JuMP ecosystem. The work is intentionally
focused on tasks that people are unlikely to want to do on a volunteer basis, or
that require deep technical knowledge of JuMP and MathOptInterface internals.

This includes things such as:
 * Fixing long-open GitHub issues (e.g., improving documentation, and usability
   improvements).
 * Maintaining code health, including readability, addressing gaps in testing,
   and reducing technical debt.
 * Maintaining wrappers for open-source solvers in the JuMP-dev GitHub
   organization.

The things not covered by the agreement are:

 * Maintenance of wrappers for commercial solvers such as CPLEX, Gurobi, and
   Xpress.

While we are conscious of the potential side effects of bringing paid
contributors into an open source community, our hope is that by focusing our
paid effort on these tasks that promote long-term sustainability, we can make it
easier both for new volunteer contributors to join the project and for our
highly valued existing contributors to develop the features they are interested
in.

The first person being funded is [Dr. Oscar Dowson](https://github.com/odow), a
core contributor to JuMP, and also a member of the Steering Committee.

Oscar will be working on a part-time basis of three days per week. His first key
tasks are improving the JuMP and MathOptInterface documentation, and finishing
tasks on the [roadmap for a JuMP 1.0 release](https://jump.dev/JuMP.jl/stable/roadmap/).

Funding paid developers is a big step for JuMP, but one that we believe sets it
up for a sustainable, long-term future.

_Miles Lubin, Joey Huchette, and Changhyun Kwon_

(Per our [conflict of interest policy](/pages/governance/#conflict-of-interest),
Oscar, who is funded by the grant, and Juan Pablo Vielma, who is a co-PI of the NSF
grant, recused themselves from Steering Committee votes on this agreement.)
