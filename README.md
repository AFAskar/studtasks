# Studtasks

PostgreSQL is now the only supported database for all environments (dev/test/prod). SQLite has been removed.

## plan

### Deployment

- use phoenix liveview for realtime sync
- use releases with a docker host | gigalixir | fly.io for deployment
- use PostgreSQL for database (e.g. local Docker, managed providers like Neon, Supabase, RDS)

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
- Ensure Postgres is running locally (you can use `docker-compose up -d db`)
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Forum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>
