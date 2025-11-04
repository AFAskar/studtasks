# Studtasks

## plan

### Deployment

- use phoenix liveview for realtime sync
- use releases with a docker host | gigalixir | fly.io for deployment
- use turso for db host

#### Mailing Services

- Resend
- Mailgun
- AWS SES

### Schema TBD

// Ownership
User has many CourseGroups
// Membership
CourseGroup has many Users
CourseGroup has many Tasks
Tasks have 3 Users (1 creator ,1 assignee)

### Features

- Epics
  maybe just being a tasks which is a grandfather of a task
- Task assignment and creation
  task with one parent or many children
- Sub Tasks
  tasks which have no children
- Calendar and kanban view

### Extras

- Analytics using posthog
- messagin within tasks
- github integration using oauth and maybe CI/CD requires Research
- Passkey auth

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Forum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>

mix phx.gen.live Courses CourseGroup course_groups name:string description:string creator_id:references:users

tasks are accessed at /groups/:id/tasks
mix phx.gen.live Courses Task tasks name:string description:string course_group_id:references:course_groups creator_id:references:users assignee_id:references:users parent_id:references:tasks

mix phx.gen.schema Courses.GroupMembership group_memberships user_id:references:users course_group_id:references:course_groups role:string
