import Config

config :joint,
  ecto_repos: [Joint.Repo]

config :joint, Joint.Repo,
  database: "joint_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
