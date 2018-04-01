defmodule Hyperex do
  @moduledoc """
  A pure-Elixir HTML renderer.
  """

  @void_tags ~w(area base br col embed hr img input link meta param source track wbr)a

  @type tag :: atom
  @type unescaped_element :: {:dangerously_unescaped, binary, renderable, binary}
  @type regular_element ::
          {tag, %{optional(:children) => :void | renderable, optional(any) => any}}
  @type element :: unescaped_element | regular_element
  @type renderable :: [element] | element | binary | number | nil

  @spec preprocess(any) :: renderable
  defp preprocess(s) when is_binary(s) do
    s
  end

  defp preprocess(s) when is_number(s) do
    to_string(s)
  end

  defp preprocess(nil), do: []

  defp preprocess([]), do: []

  defp preprocess([h | t]), do: [preprocess(h) | preprocess(t)]

  defp preprocess({func_name, meta, args}) when is_atom(func_name) do
    preprocess_call(func_name, meta, args)
  end

  defp preprocess({{:., _, _} = func_ref, meta, args}) do
    preprocess_call(func_ref, meta, args)
  end

  defp preprocess_call(:__block__, _meta, items) do
    Enum.map(items, &preprocess/1)
  end

  defp preprocess_call(:^, _meta, [arg]), do: arg

  defp preprocess_call(:-, _meta, [{user_func, meta, opts}]) do
    # It’s a user-defined element
    {tag, meta, props} = preprocess_elem(user_func, meta, opts)
    {tag, meta, [props]}
  end

  defp preprocess_call(:-, _meta, bad_args) do
    raise "Invalid user-defined call: #{inspect(bad_args)}"
  end

  defp preprocess_call(tag, meta, opts) when is_list(opts) or opts === nil do
    # It’s a native element
    {tag, meta, props} = preprocess_elem(tag, meta, opts)
    {:{}, meta, [tag, props]}
  end

  defp preprocess_elem(tag, meta, nil) do
    preprocess_elem(tag, meta, [[]])
  end

  defp preprocess_elem(tag, meta, []) do
    preprocess_elem(tag, meta, [[]])
  end

  defp preprocess_elem(tag, meta, [a, b]) when is_list(a) and is_list(b) do
    preprocess_elem(tag, meta, [a ++ b])
  end

  defp preprocess_elem(tag, meta, [v]) when is_binary(v) or is_number(v) or v === :void do
    preprocess_elem(tag, meta, [[do: v]])
  end

  defp preprocess_elem(tag, meta, [opts]) when is_list(opts) do
    children_ast =
      case Keyword.get(opts, :do) do
        :void -> :void
        nil -> nil
        e -> preprocess(e)
      end

    props_ast = {
      :%{},
      [],
      opts
      |> Keyword.delete(:do)
      |> Keyword.put_new(:children, children_ast)
    }

    {tag, meta, props_ast}
  end

  defp preprocess_elem(tag, meta, [map]) do
    {tag, meta, map}
  end

  defp preprocess_elem(tag, meta, [map, [do: block]]) do
    children_ast =
      case block do
        :void -> :void
        nil -> nil
        e -> preprocess(e)
      end

    props_ast =
      quote do
        Map.put(unquote(map), :children, unquote(children_ast))
      end
    {tag, meta, props_ast}
  end

  @doc """
  Transforms Hyperex DSL code to renderable elements.

  Use `render/1` to convert the returned renderable elements into
  iodata or strings.

  ## Example

      iex> import Hyperex
      iex> require Hyperex
      iex> hyperex(html do h1 do "Hello" end end)
      {:html, %{children: {:h1, %{children: "Hello"}}}}
  """
  defmacro hyperex(do: block) do
    preprocess(block)
  end

  defmacro hyperex(ast) do
    preprocess(ast)
  end

  defp prop_key_to_iodata(key) when is_atom(key) do
    Atom.to_string(key)
  end

  defp prop_key_to_iodata(key) when is_binary(key) do
    Plug.HTML.html_escape_to_iodata(key)
  end

  defp prop_to_iodata(_key, nil), do: ""
  defp prop_to_iodata(_key, false), do: ""
  defp prop_to_iodata(key, true), do: prop_key_to_iodata(key)

  defp prop_to_iodata(key, n) when is_number(n) do
    prop_to_iodata(key, to_string(n))
  end

  defp prop_to_iodata(key, value) when is_binary(value) do
    ek = prop_key_to_iodata(key)
    ev = Plug.HTML.html_escape_to_iodata(value)
    [ek, ?=, ?" | [ev, ?"]]
  end

  defp props_to_iodata([]), do: []

  defp props_to_iodata([{key, value} | props]) do
    [prop_to_iodata(key, value), ?\s | props_to_iodata(props)]
  end

  defp props_to_iodata(props) when is_map(props) do
    props_to_iodata(Map.to_list(props))
  end

  @doc """
  Creates HTML iodata from elements.

  ## Example

      iex> import Hyperex
      iex> require Hyperex
      iex> renderable = hyperex(html do h1 do "Hello" end end)
      {:html, %{children: {:h1, %{children: "Hello"}}}}
      iex> render(renderable)
      [
        60,
        "html",
        32,
        [],
        62,
        [60, "h1", 32, [], 62, "Hello", "</", "h1", 62],
        "</",
        "html",
        62
      ]
      iex> to_string(render(renderable))
      "<html ><h1 >Hello</h1></html>"
  """
  @spec render(renderable) :: iodata
  def render(renderable)

  def render(s) when is_binary(s) do
    Plug.HTML.html_escape_to_iodata(s)
  end

  def render(nil), do: ""

  def render(n) when is_number(n) do
    to_string(n)
  end

  def render([]), do: []
  def render([h | t]), do: [render(h), render(t)]

  def render({:dangerously_unescaped, prefix, children, suffix}) do
    [prefix, render(children), suffix]
  end

  def render({tag, props}) do
    children = props[:children]
    tag_s = Atom.to_string(tag)
    props_s = props_to_iodata(Map.delete(props, :children))

    if children === :void or (children === nil and tag in @void_tags) do
      [?<, tag_s, ?\s, props_s, "/>"]
    else
      [?<, tag_s, ?\s, props_s, ?>, render(children), "</", tag_s, ?>]
    end
  end

  @doc """
  A helper that returns an HTML5 doctype.

  ## Example

      iex> import Hyperex
      iex> require Hyperex
      iex> to_string render hyperex(
      ...>   -html5_doctype do
      ...>     html do
      ...>       body do
      ...>         "hello"
      ...>       end
      ...>     end
      ...>   end
      ...> )
      "<!DOCTYPE html><html ><body >hello</body></html>"
  """
  def html5_doctype(%{children: children}) do
    {:dangerously_unescaped, ~s{<!DOCTYPE html>}, children, ""}
  end
end
