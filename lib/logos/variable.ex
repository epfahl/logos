defmodule Logos.Variable do
  defstruct [:id]

  @doc """
  Define a new logical variable with the given identifier `id`.

  ## Examples
      iex> Logos.Variable.new(1)
      %Logos.Variable{id: 1}
  """
  def new(id), do: %__MODULE__{id: id}
end
