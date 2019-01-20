defmodule Hyperex do
  @moduledoc """
  A pure-Elixir HTML renderer.
  """

  @void_tags ~w(area base br col embed hr img input link meta param source track wbr)

  @type tag :: atom
  @type unescaped_element :: {:dangerously_unescaped, binary, renderable, binary}
  @type regular_element ::
          {tag, %{optional(:children) => :void | renderable, optional(any) => any}}
  @type element :: unescaped_element | regular_element
  @type renderable :: [element] | element | binary | number | nil

  @doc """
  This function should not be directly used. It has to be public because the
  `h` macro inserts calls to `merge_props`.
  """
  def merge_props([]), do: %{}
  def merge_props([a | b]) do
    Map.merge(Map.new(a), merge_props(b))
  end

  defp preprocess_arg(:void) do
    [children: :void]
  end

  defp preprocess_arg([{:do, {:__block__, _, expr}}]) do
    [children: expr]
  end

  defp preprocess_arg([{:do, expr}]) do
    [children: expr]
  end

  defp preprocess_arg(list) when is_list(list) do
    Enum.map(
      list,
      fn
        {:do, children} -> {:children, children}
        {key, value} -> {key, value}
      end
    )
  end

  defp preprocess_arg({:%{}, _, props}) when is_list(props) do
    props
  end

  defp preprocess_arg(literal) when is_binary(literal) or is_number(literal) do
    [children: literal]
  end

  defp preprocess_arg({name, meta, args}) when is_atom(name) do
    {name, meta, args}
  end

  defp preprocess_args(args) do
    quote do
      merge_props(unquote([[{:children, nil}] | Enum.map(args, &preprocess_arg/1)]))
    end
  end

  defp preprocess([[do: {:__block__, _, block}]]) do
    block
  end
  defp preprocess([tag_expr | args]) do
    preprocess_elem(tag_expr, preprocess_args(args))
  end

  defp preprocess_elem(tag, props) when is_atom(tag) do
    preprocess_elem(Atom.to_string(tag), props)
  end
  defp preprocess_elem(tag, props) when is_binary(tag) do
    quote do
      {unquote(tag), unquote(props)}
    end
  end
  defp preprocess_elem({tag_fun, tag_meta, nil}, props) when is_atom(tag_fun) do
    {tag_fun, tag_meta, [props]}
  end
  defp preprocess_elem({tag_fun = {:., _, [{:__aliases__, _, _}, _]}, tag_meta, []}, props) do
    {tag_fun, tag_meta, [props]}
  end

  @doc """
  Generates renderable elements.

  The first parameter should be the tag name or a function name. Tag names
  can be atoms or strings. If the first parameter is a function, then it
  should return renderable elements.

  The next parameters are what is called “props” in the React world. Each of
  these parameters must be a keyword list or a map. These maps are merged
  during rendering (values in the rightmost ones override values in the
  leftmost ones, see `Map.merge/2`).

  If the last parameter is not a map or a keyword list, then it is used as
  the `children` prop. So `h :div, "foo"` is equivalent to
  `h :div, [children: "foo"]`.

  Children can be rendered with a `children` prop or an optional
  `do … end` block.

  Use `render/1` to convert the returned renderable elements into
  iodata or strings.

  ## Example

      iex> import Hyperex
      iex> require Hyperex
      iex> h :html do
      ...>   h :h1 do "Hello" end
      ...> end
      {"html", %{children: {"h1", %{children: "Hello"}}}}
  """
  defmacro h(a), do: preprocess([a])
  defmacro h(a, b), do: preprocess([a, b])
  defmacro h(a, b, c), do: preprocess([a, b, c])
  defmacro h(a, b, c, d), do: preprocess([a, b, c, d])
  defmacro h(a, b, c, d, e), do: preprocess([a, b, c, d, e])
  defmacro h(a, b, c, d, e, f), do: preprocess([a, b, c, d, e, f])
  defmacro h(a, b, c, d, e, f, g), do: preprocess([a, b, c, d, e, f, g])
  defmacro h(a, b, c, d, e, f, g, h), do: preprocess([a, b, c, d, e, f, g, h])

  defp prop_key_to_iodata(key) when is_atom(key) do
    Atom.to_string(key)
  end

  defp prop_key_to_iodata(key) when is_binary(key) do
    Plug.HTML.html_escape_to_iodata(key)
  end

  defp prop_to_iodata(:children, _), do: ""
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

  @spec props_to_iodata([{atom | binary, any}] | %{optional(atom | binary) => any}) :: iodata
  defp props_to_iodata(props) do
    props
    |> Enum.map(fn {key, value} -> prop_to_iodata(key, value) end)
    |> Enum.intersperse(?\s)
  end

  @doc """
  Creates HTML iodata from elements.

  ## Example

      iex> import Hyperex
      iex> require Hyperex
      iex> renderable = h :html do h :h1 do "Hello" end end
      {"html", %{children: {"h1", %{children: "Hello"}}}}
      iex> render(renderable)
      [
        60,
        "html",
        32,
        [""],
        62,
        [60, "h1", 32, [""], 62, "Hello", "</", "h1", 62],
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

  def render({tag, props = %{children: children}}) when is_binary(tag) do
    props_s = props_to_iodata(props)

    if children === :void or (children === nil and tag in @void_tags) do
      [?<, tag, ?\s, props_s, "/>"]
    else
      [?<, tag, ?\s, props_s, ?>, render(children), "</", tag, ?>]
    end
  end

  @doc """
  A helper that prepends an HTML5 doctype.

  ## Example

      iex> import Hyperex
      iex> require Hyperex
      iex> to_string render(
      ...>   h html5_doctype do
      ...>     h :html do
      ...>       h :body do
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
