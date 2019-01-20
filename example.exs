defmodule HyperexExample do
  require Hyperex
  import Hyperex

  # This thing is called a “function component” in the React world.
  # A component is a function that generates renderable elements.
  # This component outputs the markup for a link that points to the
  # profile of someone.
  defp user_link(%{user: user}) do
    h :a, class: "user-link", href: "/user/#{user.id}" do
      user.name
    end
  end

  defp datetime(props) do
    {dt, props} = Map.pop props, :datetime
    h :time, datetime: to_string(dt) do
      props.children || to_string(dt)
    end
  end

  defp comment(%{comment: comment}) do
    h :div, class: "comment" do
      h :div, class: "comment-meta" do
        # `datetime` is a user-defined function and not a “native” HTML tag,
        h datetime, datetime: comment.created_at
        " by "
        h user_link, user: comment.author
      end

      h :p, class: "comment-text" do
        comment.text
      end
    end
  end

  defp reply_form(%{}) do
    h :form, action: "test" do
      h :textarea, name: "text", placeholder: "Write a reply…"
      h :button, type: "submit" do
        "Reply"
      end
    end
  end

  defp thread(%{thread: thread}) do
    h :div, class: "thread" do
      h :div, class: "comments" do
        Enum.map(thread.comments, fn c ->
          h comment, %{comment: c}
        end)
      end

      h reply_form
    end
  end

  defp page(props) do
    head =
      h :head do
        h :meta, charset: "utf-8"

        # Same as `title do props.title end`
        h :title, children: props.title
      end

    body =
      h :body do
        h :header do
          # This is a shortcut for `span do "Hyperex example" end`
          h :span, "Hyperex example"
        end

        h :main do
          h :h1 do
            props.title
          end

          props.children
        end

        h :footer, "footnote"
      end

      h Hyperex.html5_doctype do
        h :html do
          head
          body
        end
      end
  end

  defp thread_page(%{thread: t}) do
    h page, title: t.title do
      h thread, thread: t
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
        h thread_page, thread: %{
          title: "Yet another HTML renderer",
          comments: comments
        }
      )

    File.write!("example.html", html)
  end
end

HyperexExample.main()
