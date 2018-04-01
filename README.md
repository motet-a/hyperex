# Hyperex

A macro-powered HTML renderer for Elixir.

```elixir
require Hyperex
import Hyperex

defp user_link(%{user: user}) do
  hyperex(
    a class: "user-link", href: "/user/#{user.id}" do
      ^user.name
    end
  )
end

hyperex(
  body do
    -user_link user: %{name: "foo", id: 123}
  end
)
|> render()
# → <body><a class="user-link" href="/user/123">foo</a></body>
```

See `example.exs`.

## Installation

Add `hyperex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hyperex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hyperex](https://hexdocs.pm/hyperex).
