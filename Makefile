# Purpose:
#
# 	To run command commands for managing the jump.dev website.
#
# Usage:
#
# 	make [dev]				Start a local webserver for previewing the website
# 	make schedule year=N	Build the schedule table for a JuMP-dev workshop

default: dev

# Start a local webserver for previewing the website.
.PHONY: dev
dev:
	bundle exec jekyll serve

# Build the schedule table for a JuMP-dev workshop.
.PHONY: schedule
schedule:
	julia assets/jump-dev-workshops/build_schedule_table.jl ${year}

