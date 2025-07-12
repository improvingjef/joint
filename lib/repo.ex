defmodule Joint.Repo do
  use Ecto.Repo,
    otp_app: :joint,
    adapter: Ecto.Adapters.Postgres
end
