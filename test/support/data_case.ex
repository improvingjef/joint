# test/support/data_case.ex
defmodule Joint.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Joint.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Joint.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Joint.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Joint.Repo, :manual)
    end

    :ok
  end
end
