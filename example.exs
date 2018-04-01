defmodule HyperexExample do
  require Hyperex

  # Let’s define a custom unary operator for delimiting the embedded markup,
  # so `~~~` is a sort of alias for `hyperex`. Of course, this is a
  # matter of taste and directly using the `hyperex` macro is perfectly
  # fine.
  defmacrop ~~~ ast do
    quote do
      Hyperex.hyperex(unquote(ast))
    end
  end

  # So, this thing is called a “component” in the React world.
  # A component is a function that generates renderable elements.
  # That’s it. This component outputs the markup for a link that
  # points to the profile of someone.
  defp user_link(%{user: user}) do
    # You can replace these `~~~` by `hyperex`.
    ~~~
      a class: "user-link", href: "/user/#{user.id}" do
        # Between a `do` and an `end`, we have to escape expressions
        # to interpolate with a `^`.
        ^user.name
      end
  end

  defp datetime(%{datetime: dt, children: children}) do
    ~~~
      time datetime: to_string(dt) do
        ^(children || to_string(dt))
      end
  end

  defp comment(%{comment: comment}) do
    ~~~
      div class: "comment" do
        div class: "comment-meta" do
          # `datetime` is an user-defined function and not a “native” HTML tag.
          # We have to inform Hyperex by prepending a `-` before `datetime`.
          # If we don’t, Hyperex will output a (non-standard) <datetime> tag.
          -datetime(datetime: comment.created_at)
          " by "
          -user_link(user: comment.author)
        end

        p class: "comment-text" do
          ^comment.text
        end
      end
  end

  defp reply_form(%{}) do
    ~~~
      form action: "test" do
        textarea name: "text", placeholder: "Write a reply…"
        button type: "submit" do
          "Reply"
        end
      end
  end

  defp thread(%{thread: thread}) do
    ~~~
      div class: "thread" do
        div class: "comments" do
          ^Enum.map(thread.comments, fn c ->
            comment %{comment: c}
          end)
        end

        -reply_form
      end
  end

  defp page(props) do
    head =
      ~~~
        head do
          meta charset: "utf-8"

          title do
            ^props.title
          end
        end

    body =
      ~~~
        body do
          header do
            # This is a shortcut for `span do "Hyperex example" end`
            span "Hyperex example"
          end

          main do
            h1 do
              ^props.title
            end

            ^props.children
          end

          footer
        end

    ~~~
      -Hyperex.html5_doctype do
        html do
          ^head
          ^body
        end
      end
  end

  defp thread_page(%{thread: t}) do
    ~~~
      -page title: t.title do
        -thread thread: t
      end
  end

  def main do
    now = NaiveDateTime.utc_now()

    comments = [
      %{
        author: %{name: "foo", id: 1},
        text: "Hyperex looks fantastic!",
        created_at: now
      },
      %{
        author: %{name: "bar", id: 2},
        text: "The quick brown fox",
        created_at: now
      },
    ]

    html =
      Hyperex.render(
        thread_page %{
          thread: %{
            title: "Yet another HTML renderer",
            comments: comments
          }
        }
      )

    File.write!("example.html", html)
  end
end

HyperexExample.main()
