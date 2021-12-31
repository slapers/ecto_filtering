defmodule EctoFiltering.Query do
  @moduledoc false

  import Ecto.Query

  def apply(queryable, filter) do
    {filter, q} = expand(filter, queryable)
    where(q, ^filter)
  end

  defp expand(nil, q), do: {nil, q}
  defp expand(n, q) when is_number(n), do: {n, q}
  defp expand(s, q) when is_binary(s), do: {s, q}
  defp expand(b, q) when is_boolean(b), do: {b, q}
  defp expand({:var, path}, q), do: exp_var(path, nil, q)

  defp expand({binop, [left, right]}, q) do
    {exp_left, q} = expand(left, q)
    {exp_right, q} = expand(right, q)
    binop(binop, exp_left, exp_right, q)
  end

  defp expand({unop, [arg]}, q) do
    {exp_arg, q} = expand(arg, q)
    unop(unop, exp_arg, q)
  end

  defp binop(:==, same, same, q), do: {dynamic(true), q}
  defp binop(:==, left, nil, q), do: {dynamic(is_nil(^left)), q}
  defp binop(:==, nil, right, q), do: {dynamic(is_nil(^right)), q}
  defp binop(:==, left, right, q), do: {dynamic(^left == ^right), q}

  defp binop(:!=, same, same, q), do: {dynamic(false), q}
  defp binop(:!=, left, nil, q), do: {dynamic(not is_nil(^left)), q}
  defp binop(:!=, nil, right, q), do: {dynamic(not is_nil(^right)), q}
  defp binop(:!=, left, right, q), do: {dynamic(^left != ^right), q}

  defp binop(:<, left, right, q), do: {dynamic(^left < ^right), q}
  defp binop(:<=, left, right, q), do: {dynamic(^left <= ^right), q}
  defp binop(:>, left, right, q), do: {dynamic(^left > ^right), q}
  defp binop(:>=, left, right, q), do: {dynamic(^left >= ^right), q}

  defp binop(:+, left, right, q), do: {dynamic(^left + ^right), q}
  defp binop(:-, left, right, q), do: {dynamic(^left - ^right), q}
  defp binop(:*, left, right, q), do: {dynamic(^left * ^right), q}
  defp binop(:/, left, right, q), do: {dynamic(^left / ^right), q}

  defp binop(:&&, left, right, q), do: {dynamic(^left and ^right), q}
  defp binop(:||, left, right, q), do: {dynamic(^left or ^right), q}

  defp unop(:!, arg, q), do: {dynamic(not (^arg)), q}

  defp exp_var(path, parent, q)

  defp exp_var([name], nil, q) do
    field_name = String.to_existing_atom(name)
    {dynamic([q], field(q, ^field_name)), q}
  end

  defp exp_var([name], parent, q) do
    parent_name = String.to_atom(parent)
    field_name = String.to_existing_atom(name)
    {dynamic([{^parent_name, p}], field(p, ^field_name)), q}
  end

  defp exp_var([name | tail], parent, q) do
    with_joined_assoc = join_assoc(q, name, parent)
    new_parent = new_parent(parent, name)
    exp_var(tail, new_parent, with_joined_assoc)
  end

  defp new_parent(nil, name), do: name
  defp new_parent(parent, name), do: "#{parent}_#{name}"

  defp join_assoc(q, assoc, nil) do
    assoc_name = String.to_existing_atom(assoc)

    if Ecto.Query.has_named_binding?(q, assoc_name) do
      q
    else
      q = Macro.escape(q)

      #
      # the as: binding_name requires a compile time atom :-(
      Code.eval_quoted(
        quote do
          join(unquote(q), :inner, [q], assoc(q, ^unquote(assoc_name)), as: unquote(assoc_name))
        end
      )
      |> elem(0)
    end
  end

  defp join_assoc(q, assoc, parent) do
    binding_name = String.to_atom("#{parent}_#{assoc}")

    if Ecto.Query.has_named_binding?(q, binding_name) do
      q
    else
      assoc_name = String.to_existing_atom(assoc)
      parent_name = String.to_existing_atom(parent)
      q = Macro.escape(q)

      #
      # the as: binding_name requires a compile time atom :-(
      Code.eval_quoted(
        quote do
          join(unquote(q), :inner, [{^unquote(parent_name), p}], assoc(p, ^unquote(assoc_name)),
            as: unquote(binding_name)
          )
        end
      )
      |> elem(0)
    end
  end
end
